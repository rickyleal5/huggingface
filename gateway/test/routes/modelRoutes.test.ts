import debug from 'debug';
const log = debug('test:modelRoutes');

import { expect } from 'chai';
import { describe, it, beforeEach, afterEach } from 'mocha';
import express from 'express';
import request from 'supertest';
import sinon from 'sinon';
import axios from 'axios';
import { mockGpt2Request, mockGpt2Response, mockErrorResponse } from '../mocks/modelMocks';

// Mock validator middleware to always pass
const passValidator = (_req: any, _res: any, next: any) => next();

// Import your routes, but override the validators
import proxyquire from 'proxyquire';
const modelRoutes = proxyquire('../../src/routes/modelRoutes', {
    '../../src/validators/modelValidators': {
        validateModelName: passValidator,
        validateGenerateRequest: [passValidator],
        __esModule: true
    },
    axios: axios
}).default;

describe('Model Routes', () => {
    let app: express.Application;
    let axiosPostStub: sinon.SinonStub;
    let axiosGetStub: sinon.SinonStub;

    beforeEach(() => {
        app = express();
        app.use(express.json());
        app.use('/', modelRoutes);
        axiosPostStub = sinon.stub(axios, 'post');
        axiosGetStub = sinon.stub(axios, 'get');
    });

    afterEach(() => {
        sinon.restore();
    });

    describe('GET /health', () => {
        it('should return 200 OK', async () => {
            const response = await request(app)
                .get('/health')
                .expect(200);
      
            log('Health check response:', response.body);
            expect(response.body).to.have.property('status', 'healthy');
        });
    });

    describe('GET /gpt2/status', () => {
        it('should return model status', async () => {
            // Mock successful response for /gpt2/status
            axiosGetStub.resolves({ data: { status: 'ready' } });

            const response = await request(app)
                .get('/gpt2/status')
                .expect(200);

            log('GPT-2 status response:', response.body);
            expect(response.body).to.have.property('status');
            expect(response.body.status).to.be.oneOf(['ready', 'loading', 'error']);
        });
    });

    describe('POST /gpt2/generate', () => {
        it('should generate text with GPT-2', async () => {
            // Mock successful response for /gpt2/generate
            axiosPostStub.resolves({ data: mockGpt2Response });

            const response = await request(app)
                .post('/gpt2/generate')
                .send(mockGpt2Request)
                .expect(200);

            log('GPT-2 generate response:', response.body);
            expect(response.body).to.deep.include(mockGpt2Response);
        });
    });

    describe('POST /non-existent-model/generate', () => {
        it('should return 404 for non-existent model', async () => {
            // Simulate axios error for non-existent model
            const error = new Error('Not found');
            (error as any).response = {
                status: 404,
                data: mockErrorResponse
            };
            (error as any).isAxiosError = true;
            axiosPostStub.rejects(error);

            const response = await request(app)
                .post('/non-existent-model/generate')
                .send(mockGpt2Request)
                .expect(404);

            log('Non-existent model response:', response.body);
            expect(response.body).to.deep.equal(mockErrorResponse);
        });
    });
}); 