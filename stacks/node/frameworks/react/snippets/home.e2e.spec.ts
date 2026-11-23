// agent-kit example: one main-path journey + an accessibility check (WCAG 2.2 AA rules via axe).
import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

test('home page shows the main heading and has no a11y violations', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag22aa']).analyze();
  expect(results.violations).toEqual([]);
});
