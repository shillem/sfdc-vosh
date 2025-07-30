export default {
  "**/*.{cls,cmp,component,css,html,js,json,md,page,trigger,xml,yaml,yml}": ["prettier --write"],
  "**/aura|**/lwc|**/*.{cls,trigger}": (filenames) => [
    `npm run code:analyze -- ${filenames.map((f) => `--target "${f}"`).join(" ")}`
  ]
};
