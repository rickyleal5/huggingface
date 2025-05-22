import { body, param } from 'express-validator';
import modelServices from '../services/modelServices';

const validateModelName = param('modelName')
    .isIn(Object.keys(modelServices))
    .withMessage('Invalid model name');

const validateGenerateRequest = [
    body('text')
        .isString()
        .trim()
        .isLength({ min: 1, max: 1000 })
        .withMessage('Text must be between 1 and 1000 characters'),
    body('max_length')
        .isInt({ min: 1, max: 1000 })
        .withMessage('Max length must be between 1 and 1000'),
    body('num_return_sequences')
        .optional()
        .isInt({ min: 1, max: 5 })
        .withMessage('Number of sequences must be between 1 and 5')
];

export { validateModelName, validateGenerateRequest }; 