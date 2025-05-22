import express, { Request, Response } from 'express';
import { HealthResponse } from '../types';

const router = express.Router();

// Health check endpoint
router.get('/health', (req: Request, res: Response<HealthResponse>) => {
    res.json({ status: 'healthy' });
});

export default router; 