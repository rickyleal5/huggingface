import { expect } from 'chai';
import { describe, it, beforeEach, afterEach } from 'mocha';
import express from 'express';
import request from 'supertest';
import sinon from 'sinon';
import axios from 'axios';
import errorHandler from '../../src/middleware/errorHandler';

describe('Rate Limiter', () => {
    let app: express.Application;
    let requestCount: number;

    beforeEach(() => {
        app = express();
        requestCount = 0;
    
        // Create a simple rate limiter middleware
        app.use((req, res, next) => {
            requestCount++;
            if (requestCount > 2) {
                return res.status(429).json({ error: 'Too many requests, please try again later.' });
            }
            next();
        });

        app.get('/test', (req, res) => res.status(200).json({ message: 'success' }));
        app.use(errorHandler);
    });

    afterEach(() => {
        sinon.restore();
    });

    it('should allow requests within rate limit', async function() {
        this.timeout(5000); // Set timeout to 5 seconds

        try {
            // Make 2 requests (within limit)
            for (let i = 0; i < 2; i++) {
                const response = await request(app)
                    .get('/test')
                    .timeout(1000); // Set request timeout to 1 second
        
                expect(response.status).to.equal(200);
                expect(response.body).to.have.property('message', 'success');
            }
        } catch (error: unknown) {
            // If we get an error, fail the test but don't get stuck
            expect.fail('Test failed: ' + (error instanceof Error ? error.message : 'Unknown error'));
        }
    });

    it('should block requests exceeding rate limit', async function() {
        this.timeout(5000); // Set timeout to 5 seconds

        try {
            // Make 3 requests (exceeding limit)
            for (let i = 0; i < 3; i++) {
                const response = await request(app)
                    .get('/test')
                    .timeout(1000); // Set request timeout to 1 second
        
                if (i < 2) {
                    expect(response.status).to.equal(200);
                    expect(response.body).to.have.property('message', 'success');
                } else {
                    expect(response.status).to.equal(429);
                    expect(response.body).to.have.property('error');
                    expect(response.body.error).to.equal('Too many requests, please try again later.');
                }
            }
        } catch (error: unknown) {
            // If we get an error, fail the test but don't get stuck
            expect.fail('Test failed: ' + (error instanceof Error ? error.message : 'Unknown error'));
        }
    });
}); 