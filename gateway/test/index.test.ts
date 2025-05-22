import { describe, beforeEach, afterEach } from 'mocha';
import sinon from 'sinon';
import express from 'express';
import proxyquire from 'proxyquire';
import axios from 'axios';

interface LoggerStub {
    info: sinon.SinonStub;
    error: sinon.SinonStub;
    warn: sinon.SinonStub;
    debug: sinon.SinonStub;
}

describe('Application', () => {
    let app: express.Application;
    let expressStub: sinon.SinonStub;
    let helmetStub: sinon.SinonStub;
    let corsStub: sinon.SinonStub;
    let loggerStub: LoggerStub;

    beforeEach(() => {
        // Stub express
        const nextMiddleware = (_req: express.Request, _res: express.Response, next: express.NextFunction) => next();
        expressStub = sinon.stub(express, 'json').returns(nextMiddleware as any);
        helmetStub = sinon.stub().returns(nextMiddleware as any);
        corsStub = sinon.stub().returns(nextMiddleware as any);

        // Create logger stub
        loggerStub = {
            info: sinon.stub(),
            error: sinon.stub(),
            warn: sinon.stub(),
            debug: sinon.stub()
        };

        // Import the app with stubbed dependencies
        const { default: createApp } = proxyquire('../src/index', {
            'express': express,
            'helmet': { default: helmetStub },
            'cors': corsStub,
            'axios': axios,
            './config/logger': {
                default: loggerStub
            }
        });

        app = createApp();
    });

    afterEach(() => {
        sinon.restore();
    });
}); 