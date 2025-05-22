module.exports = {
    env: {
        es2020: true,
        node: true
    },
    extends: [
        'eslint:recommended',
        'plugin:@typescript-eslint/recommended'
    ],
    parser: '@typescript-eslint/parser',
    parserOptions: {
        ecmaVersion: 2020,
        sourceType: 'module',
        project: './tsconfig.json'
    },
    plugins: ['@typescript-eslint'],
    rules: {
        quotes: ['error', 'single'],
        indent: ['error', 4],
        semi: ['error', 'always'],
        'arrow-spacing': ['error', { before: true, after: true }],
        'comma-dangle': ['error', 'never'],
        'max-len': ['error', { code: 160 }],
        '@typescript-eslint/explicit-function-return-type': 'error',
        '@typescript-eslint/no-explicit-any': 'error',
        '@typescript-eslint/no-unused-vars': 'error'
    }
};
