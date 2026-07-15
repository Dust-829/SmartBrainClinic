import { execFileSync } from 'node:child_process'
import path from 'node:path'

import { expect, test } from '@playwright/test'

type DoctorPrescriptionFixture = {
  doctor_uuid: string
  encounter_url: string
}

function createFixture(): DoctorPrescriptionFixture {
  const backendRoot = path.resolve(process.cwd(), '../backend')
  const output = execFileSync('python', ['scripts/create_doctor_prescription_e2e_fixture.py'], {
    cwd: backendRoot,
    encoding: 'utf8',
    env: { ...process.env, PYTHONUTF8: '1' },
  })
  const jsonLine = output
    .trim()
    .split(/\r?\n/)
    .reverse()
    .find((line) => line.trim().startsWith('{'))

  if (!jsonLine) {
    throw new Error(`Fixture script did not return JSON: ${output}`)
  }
  return JSON.parse(jsonLine) as DoctorPrescriptionFixture
}

test('doctor confirms a controlled prescription regression record', async ({ page }) => {
  test.setTimeout(120_000)
  const fixture = createFixture()

  await page.goto('/doctor/login')
  const form = page.locator('.doctor-login__form')
  await expect(form).toBeVisible()
  await form.locator('select').nth(0).selectOption('XNK')
  await form.locator('select').nth(1).selectOption(fixture.doctor_uuid)
  await form.locator('button[type="button"]').click()
  await expect(page).toHaveURL(/\/doctor\/workbench/)

  await page.goto(fixture.encounter_url)
  const recordForm = page.locator('.doctor-encounter__form')
  await expect(recordForm).toBeVisible()
  const requiredFields = [
    'headache with high blood pressure',
    'headache for two days without acute warning symptoms',
    'history of high blood pressure',
    'vital signs need in-person confirmation',
    'high blood pressure under evaluation',
  ]
  for (const [index, value] of requiredFields.entries()) {
    await recordForm.locator('textarea').nth(index).fill(value)
  }

  await page.locator('.doctor-encounter__hero-actions .doctor-encounter__primary').click()
  await expect(page.getByText('AI 处方建议')).toBeVisible()
  const recommendationButton = page.getByRole('button', { name: '生成 AI 处方建议' })
  await expect(recommendationButton).toBeEnabled()
  const recommendationResponse = page.waitForResponse((response) =>
    response.url().includes('/api/v1/pharmacy/recommend-prescription') && response.request().method() === 'POST',
  )
  await recommendationButton.click()
  await expect((await recommendationResponse).status()).toBe(200)

  const pendingItem = page.locator('.doctor-encounter__prescription-item').first()
  await expect(pendingItem).toBeVisible()
  const quantityInput = pendingItem.locator('input[type="number"]')
  await quantityInput.fill('2')
  await expect(quantityInput).toHaveValue('2')
  await expect(page.getByRole('button', { name: /医生确认并开立/ })).toBeEnabled()
})
