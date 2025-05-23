// eslint.config.js
const { defineConfig } = require("eslint/config");
const prettierFlat = require("eslint-config-prettier/flat");
const prettierRecommended = require("eslint-plugin-prettier/recommended");
const sfLwcRecommended = require("@salesforce/eslint-config-lwc/recommended");

module.exports = defineConfig([
  {
    files: ["force-app/main/default/lwc/**/*.js"],
    extends: [sfLwcRecommended, prettierRecommended, prettierFlat]
  }
]);
