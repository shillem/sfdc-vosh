module.exports = {
  "**/*.{cmp,component,css,html,js,json,md,page,trigger,xml,yaml,yml}": ["prettier --write"],
  "**/aura|lwc/**": ["eslint"],
  "**/*.cls": (filenames) => [
    `prettier --write ${filenames.join(" ")}`,
    `sfdx scanner run --engine pmd --pmdconfig config/ruleset.xml --normalize-severity --severity-threshold 3 --target \"${filenames}\"`
  ]
};
