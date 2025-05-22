export const mockGpt2Request = {
    text: 'Hello, how are you?',
    max_length: 50
};

export const mockGpt2Response = {
    text: 'Hello, how are you? I hope you are doing well.',
    usage: {
        prompt_tokens: 7,
        completion_tokens: 12,
        total_tokens: 19
    }
};

export const mockNonExistentModelRequest = {
    modelId: 'non-existent-model',
    input: {
        text: 'Test input',
        parameters: {
            temperature: 0.7,
            max_tokens: 50
        }
    }
};

export const mockErrorResponse = {
    error: {
        code: 'MODEL_NOT_FOUND',
        message: 'The model \'non-existent-model\' was not found',
        status: 404
    }
};

export const mockModelList = [
    {
        id: 'gpt2',
        name: 'GPT-2',
        description: 'A transformer-based language model',
        max_tokens: 1024,
        supported_parameters: ['temperature', 'max_tokens', 'top_p', 'frequency_penalty', 'presence_penalty']
    },
    {
        id: 'gpt2-medium',
        name: 'GPT-2 Medium',
        description: 'Medium-sized GPT-2 model',
        max_tokens: 1024,
        supported_parameters: ['temperature', 'max_tokens', 'top_p', 'frequency_penalty', 'presence_penalty']
    }
]; 