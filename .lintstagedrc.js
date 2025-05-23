module.exports = {
  "**/*.{cls,cmp,component,css,html,js,json,md,page,trigger,xml,yaml,yml}": ["prettier --write"],
  "**/aura|lwc/**": ["eslint"],
  "**/*.{cls,trigger}": [
    "sf code-analyzer run --rule-selector pmd:Apex --rule-selector AppExchange --severity-threshold Low --target"
  ]
};
