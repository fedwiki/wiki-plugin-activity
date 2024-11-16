import globals from 'globals'
import pluginJs from '@eslint/js'

/** @type {import('eslint').Linter.Config[]} */
export default [
  { ignores: ['client/*'] },
  {
    languageOptions: {
      globals: {
        wiki: 'readonly',
        ...globals.browser,
        ...globals.jquery,
        ...globals.mocha,
      },
    },
  },
  pluginJs.configs.recommended,
]
