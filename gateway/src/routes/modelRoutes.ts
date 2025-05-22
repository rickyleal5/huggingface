import express, { Request, Response } from 'express';
import axios from 'axios';
import { validationResult } from 'express-validator';
import { validateModelName, validateGenerateRequest } from '../validators/modelValidators';
import modelServices from '../services/modelServices';
import logger from '../config/logger';

const router = express.Router();

// Health check endpoint
router.get('/health', (req: Request, res: Response) => {
    res.json({ status: 'healthy' });
});

// Model status endpoint
router.get('/:modelName/status', validateModelName, async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    const { modelName } = req.params;
    const serviceUrl = modelServices[modelName];

    try {
        const response = await axios.get(`${serviceUrl}/health`, { timeout: 5000 });
        res.json(response.data);
    } catch (error) {
        logger.error(`Error checking model status: ${error instanceof Error ? error.message : 'Unknown error'}`);
        res.status(500).json({ error: 'Failed to check model status' });
    }
});

// Generate text endpoint
router.post('/:modelName/generate', [validateModelName, ...validateGenerateRequest], async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    const { modelName } = req.params;
    const serviceUrl = modelServices[modelName];

    try {
        const response = await axios.post(`${serviceUrl}/models/${modelName}/generate`, req.body, {
            timeout: 30000,
            headers: {
                'Content-Type': 'application/json'
            }
        });
        res.json(response.data);
    } catch (error) {
        logger.error(`Error generating text: ${error instanceof Error ? error.message : 'Unknown error'}`);
        if (axios.isAxiosError(error) && error.response) {
            res.status(error.response.status).json(error.response.data);
        } else {
            res.status(500).json({ error: 'Failed to generate text' });
        }
    }
});

export default router; 