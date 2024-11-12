import globals from "globals";
import pluginJs from "@eslint/js";

/** @type {import('eslint').Linter.Config[]} */
export default [
  {
    languageOptions: {
      globals: {
        wiki: "writable",
        ...globals.browser,
        ...globals.jquery,
        ...globals.mocha,
      },
    },
  },
  pluginJs.configs.recommended,
];
