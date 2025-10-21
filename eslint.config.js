import aura from "@salesforce/eslint-plugin-aura";
import { defineConfig } from "eslint/config";
import eslintConfigPrettier from "eslint-config-prettier/flat";
import jestPlugin from "eslint-plugin-jest";
import lwcConfig from "@salesforce/eslint-config-lwc";
import lwcPlugin from "@lwc/eslint-plugin-lwc";

export default defineConfig([
  {
    files: ["*.js"],

    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module"
    },

    rules: {
      indent: ["off", "tab"],
      "linebreak-style": ["error", "unix"],
      "no-console": "warn",
      "no-undef": "off",

      "no-unused-vars": [
        "warn",
        {
          args: "none"
        }
      ],

      quotes: ["warn", "double"],
      semi: ["error", "always"]
    }
  },
  {
    files: ["**/aura/**/*.js"],

    extends: [aura.configs.recommended],

    rules: {
      "consistent-return": "off",
      "no-console": "warn",
      "no-unused-expressions": "off",
      "no-unused-vars": "warn",
      "vars-on-top": "off"
    }
  },
  {
    files: ["**/lwc/**/*.js"],

    extends: [lwcConfig.configs.recommended],

    plugins: {
      "@lwc/lwc": lwcPlugin
    }
  },
  {
    files: ["**/*.spec.js", "**/*.test.js"],

    plugins: {
      jest: jestPlugin
    },

    languageOptions: {
      globals: jestPlugin.environments.globals.globals
    },

    rules: {
      "jest/no-disabled-tests": "warn",
      "jest/no-focused-tests": "error",
      "jest/no-identical-title": "error",
      "jest/prefer-to-have-length": "warn",
      "jest/valid-expect": "error"
    }
  },
  eslintConfigPrettier
]);
