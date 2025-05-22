import { ModelServices } from '../types';

const modelServices: ModelServices = {
    gpt2: process.env.GPT2_SERVICE_URL || 'http://model-server:8000'
    // Add more models as needed
};

export default modelServices; 