module.exports = {
  root: true,
  env: {
    browser: true,
    es2021: true,
  },
  parserOptions: {
    ecmaVersion: 2021,
    sourceType: 'script',
  },
  extends: ['eslint:recommended'],
  globals: {
    google: 'readonly',
    S: 'writable',
    PLAT: 'readonly',
    platLink: 'readonly',
    _ST_COLORS: 'readonly',
    _SCHED_ST_COL: 'readonly',
  },
  rules: {
    'no-console': 'off',
    'no-unused-vars': ['warn', { args: 'none', ignoreRestSiblings: true }],
  },
};
