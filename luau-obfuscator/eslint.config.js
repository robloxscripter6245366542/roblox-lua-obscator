// Flat ESLint config (ESLint 9 + typescript-eslint).
import js from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['dist/**', 'node_modules/**', 'coverage/**'] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: { process: 'readonly', Buffer: 'readonly', console: 'readonly' },
    },
    rules: {
      '@typescript-eslint/no-non-null-assertion': 'off',
      '@typescript-eslint/consistent-type-imports': 'warn',
      'no-fallthrough': 'error',
      eqeqeq: ['error', 'always'],
    },
  },
);
