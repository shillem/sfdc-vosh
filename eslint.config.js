import aura from "@salesforce/eslint-plugin-aura";
import { defineConfig } from "eslint/config";
import lwcConfig from "@salesforce/eslint-config-lwc";
import lwcPlugin from "@lwc/eslint-plugin-lwc";
import prettierRecommended from "eslint-plugin-prettier/recommended";

export default defineConfig([
  prettierRecommended,
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
  }
]);
