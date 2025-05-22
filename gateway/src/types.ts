import { Request, Response, NextFunction } from 'express';
import { ValidationError as ExpressValidatorError } from 'express-validator';

export interface ModelService {
  url: string;
  name: string;
}

export interface ModelServices {
  [key: string]: string;
}

export interface GenerateRequest {
  text: string;
  max_length: number;
  num_return_sequences?: number;
}

export interface GenerateTextRequest {
  text: string;
  max_length?: number;
  num_return_sequences?: number;
}

export interface GenerateTextResponse {
  result: {
    generated_text: string;
    [key: string]: unknown;
  };
}

export interface ModelStatus {
  status: string;
  model: string;
  task: string;
  environment: string;
  model_loaded: boolean;
}

export interface HealthResponse {
  status: string;
}

export interface ErrorResponse {
  error: string;
}

export type ValidationError = {
  errors: ExpressValidatorError[];
};

export type ErrorHandler = (
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) => void; 