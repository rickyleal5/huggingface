import 'dotenv/config';
import express from 'express';
import { helmetConfig, corsConfig } from './config/security';
import limiter from './config/rateLimiter';
import logger from './config/logger';
import modelRoutes from './routes/modelRoutes';
import gatewayRoutes from './routes/gatewayRoutes';
import errorHandler from './middleware/errorHandler';

const app = express();
const port = process.env.PORT || 3000;

// Apply security middleware
app.use(helmetConfig);
app.use(corsConfig);
app.use(express.json({ limit: '1mb' }));
app.use(limiter);

// Routes
app.use('/', gatewayRoutes);  // Mount gateway routes at root
app.use('/models', modelRoutes);  // Mount model routes under /models

// Error handling
app.use(errorHandler);

app.listen(port, () => {
    logger.info(`Gateway server running on port ${port}`);
}); 