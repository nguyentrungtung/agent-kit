<?php

declare(strict_types=1);

// agent-kit: PER Coding Style 2.0 (PHP-FIG successor of PSR-12) + strict, safe extras.
// Changing rules = team decision (ADR). Never relax a rule to make a diff pass.

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__)
    ->exclude(['vendor', 'var', 'storage', 'bootstrap/cache', 'node_modules', 'public/build'])
    ->notName('*.blade.php');

return (new PhpCsFixer\Config())
    ->setRiskyAllowed(true)
    ->setParallelConfig(PhpCsFixer\Runner\Parallel\ParallelConfigFactory::detect())
    ->setCacheFile(__DIR__ . '/var/cache/.php-cs-fixer.cache')
    ->setRules([
        '@PER-CS2.0' => true,
        '@PER-CS2.0:risky' => true,
        '@PHP82Migration' => true,
        'declare_strict_types' => true,
        'strict_comparison' => true,
        'strict_param' => true,
        'array_syntax' => ['syntax' => 'short'],
        'single_quote' => true,
        'no_unused_imports' => true,
        'ordered_imports' => ['sort_algorithm' => 'alpha', 'imports_order' => ['class', 'function', 'const']],
        'global_namespace_import' => ['import_classes' => true, 'import_constants' => false, 'import_functions' => false],
        'trailing_comma_in_multiline' => ['elements' => ['arrays', 'arguments', 'parameters', 'match']],
        'no_superfluous_phpdoc_tags' => ['allow_mixed' => true],
        'phpdoc_trim' => true,
        'phpdoc_order' => true,
        'void_return' => true,
        'modernize_types_casting' => true,
        'no_useless_else' => true,
        'no_useless_return' => true,
        'simplified_null_return' => true,
    ])
    ->setFinder($finder);
