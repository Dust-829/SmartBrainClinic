import { expect, test } from '@playwright/test'

test('doctor login page renders without a browser-side failure', async ({ page }) => {
  await page.goto('/doctor/login')

  await expect(page.locator('.doctor-login')).toBeVisible()
  await expect(page.locator('.doctor-login__hero h1')).toBeVisible()
  await expect(page.locator('.doctor-login__form')).toBeVisible()
})
