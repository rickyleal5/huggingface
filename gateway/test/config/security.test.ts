import { expect } from 'chai';
import { describe, it, beforeEach, afterEach } from 'mocha';
import express from 'express';
import request from 'supertest';
import sinon from 'sinon';
import axios from 'axios';
import { helmetConfig, corsConfig } from '../../src/config/security';

describe('Security Middleware', () => {
    let app: express.Application;
    let axiosGetStub: sinon.SinonStub;

    beforeEach(() => {
        app = express();
        app.use(helmetConfig);
        app.use(corsConfig);
        app.get('/test', (req, res) => res.status(200).json({ message: 'success' }));
    
        // Stub axios
        axiosGetStub = sinon.stub(axios, 'get');
    });

    afterEach(() => {
        sinon.restore();
    });

    it('should set security headers', async () => {
    // Mock successful response
        axiosGetStub.resolves({ data: { status: 'success' } });

        const response = await request(app)
            .get('/test')
            .expect(200);

        // Check for common security headers
        expect(response.headers).to.have.property('x-content-type-options');
        expect(response.headers).to.have.property('x-frame-options');
        expect(response.headers).to.have.property('x-xss-protection');
        expect(response.headers).to.have.property('strict-transport-security');
        expect(response.headers).to.have.property('content-security-policy');
    });

    it('should prevent clickjacking', async () => {
    // Mock successful response
        axiosGetStub.resolves({ data: { status: 'success' } });

        const response = await request(app)
            .get('/test')
            .expect(200);

        expect(response.headers['x-frame-options']).to.equal('DENY');
    });

    it('should prevent MIME type sniffing', async () => {
    // Mock successful response
        axiosGetStub.resolves({ data: { status: 'success' } });

        const response = await request(app)
            .get('/test')
            .expect(200);

        expect(response.headers['x-content-type-options']).to.equal('nosniff');
    });

    it('should enable XSS protection', async () => {
    // Mock successful response
        axiosGetStub.resolves({ data: { status: 'success' } });

        const response = await request(app)
            .get('/test')
            .expect(200);

        expect(response.headers['x-xss-protection']).to.equal('0');
    });

    it('should enforce HTTPS', async () => {
    // Mock successful response
        axiosGetStub.resolves({ data: { status: 'success' } });

        const response = await request(app)
            .get('/test')
            .expect(200);

        expect(response.headers['strict-transport-security']).to.include('max-age=');
    });
}); 