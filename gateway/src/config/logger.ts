import winston from 'winston';

const logger = winston.createLogger({
    level: process.env.NODE_ENV === 'test' ? 'debug' : 'info',
    format: winston.format.json(),
    transports: [
        new winston.transports.Console(),
        ...(process.env.NODE_ENV === 'test' ? [] : [
            new winston.transports.File({ filename: 'error.log', level: 'error' }),
            new winston.transports.File({ filename: 'combined.log' })
        ])
    ]
});

export default logger; 