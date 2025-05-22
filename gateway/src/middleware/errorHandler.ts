import { Request, Response } from 'express';
import logger from '../config/logger';
import { ErrorHandler } from '../types';
import { AxiosError } from 'axios';

interface ServiceError extends Error {
    isAxiosError?: boolean;
    status?: number;
    response?: {
        status: number;
        data: {
            error?: string;
        };
    };
}

const errorHandler: ErrorHandler = (err: Error, req: Request, res: Response) => {
    logger.error(err.stack);

    // Handle 404 errors
    if (err.name === 'NotFoundError') {
        return res.status(404).json({ error: 'Not Found' });
    }

    // Handle validation errors
    if (err.name === 'ValidationError' || (err as ServiceError).status === 400) {
        return res.status(400).json({ error: err.message });
    }

    // Handle service errors
    const serviceError = err as ServiceError;
    if (serviceError.isAxiosError && serviceError.response) {
        const status = serviceError.response.status;
        const message = serviceError.response.data.error || err.message;
        return res.status(status).json({ error: message });
    }

    // Handle all other errors
    res.status(500).json({ error: 'Internal Server Error' });
};

export default errorHandler; 