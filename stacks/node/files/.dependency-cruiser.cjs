// agent-kit: architecture rules for JS/TS (run: kit-run arch). Add layer rules for your folders below.
/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  forbidden: [
    { name: 'no-circular', severity: 'error', from: {}, to: { circular: true } },
    { name: 'not-to-unresolvable', severity: 'error', from: {}, to: { couldNotResolve: true } },
    {
      name: 'no-prod-to-dev-deps',
      severity: 'error',
      from: { path: '^src', pathNot: '\\.(spec|test)\\.[jt]sx?$' },
      to: { dependencyTypes: ['npm-dev'], dependencyTypesNot: ['type-only'] },
    },
    {
      name: 'no-orphans',
      severity: 'warn',
      from: {
        orphan: true,
        pathNot: ['\\.d\\.ts$', '(^|/)\\.[^/]+\\.[cm]?[jt]s$', '\\.(spec|test)\\.[jt]sx?$'],
      },
      to: {},
    },
    // Example layering — uncomment and adapt to .agent/rules/project/modules.md:
    // { name: 'domain-is-pure', severity: 'error', from: { path: '^src/domain' }, to: { path: '^src/(infra|api|ui)' } },
    // Backend modules: other modules only through index.ts
    // { name: 'module-public-api-only', severity: 'error', from: { path: '^src/modules/([^/]+)/' },
    //   to: { path: '^src/modules/([^/]+)/.+', pathNot: ['^src/modules/$1/', '^src/modules/[^/]+/index\\.ts$'] } },
    // Frontend features: other features only through index.ts; shared never imports features
    // { name: 'feature-public-api-only', severity: 'error', from: { path: '^src/features/([^/]+)/' },
    //   to: { path: '^src/features/([^/]+)/.+', pathNot: ['^src/features/$1/', '^src/features/[^/]+/index\\.tsx?$'] } },
    // { name: 'shared-not-to-features', severity: 'error', from: { path: '^src/shared/' }, to: { path: '^src/features/' } },
  ],
  options: {
    doNotFollow: { path: 'node_modules' },
    tsPreCompilationDeps: true,
    tsConfig: { fileName: 'tsconfig.json' },
    enhancedResolveOptions: {
      exportsFields: ['exports'],
      conditionNames: ['import', 'require', 'node', 'default', 'types'],
    },
  },
};
