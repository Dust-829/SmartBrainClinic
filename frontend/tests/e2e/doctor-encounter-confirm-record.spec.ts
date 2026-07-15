import { execFileSync } from 'node:child_process'
import path from 'node:path'

import { expect, test } from '@playwright/test'

type DoctorPrescriptionFixture = {
  doctor_uuid: string
  register_uuid: string
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

  const orderRecommendationButton = page.locator('.doctor-encounter__ai-order-workspace .doctor-encounter__secondary')
  await expect(orderRecommendationButton).toBeEnabled()
  const orderRecommendationResponse = page.waitForResponse((response) =>
    response.url().includes('/api/v1/medical/orders/ai-recommendation') && response.request().method() === 'POST',
  )
  await orderRecommendationButton.click()
  await expect((await orderRecommendationResponse).status()).toBe(200)
  await expect(page.locator('.doctor-encounter__ai-order-context')).toBeVisible()

  const pendingItem = page.locator('.doctor-encounter__prescription-item').first()
  await expect(pendingItem).toBeVisible()
  const quantityInput = pendingItem.locator('input[type="number"]')
  await quantityInput.fill('2')
  await expect(quantityInput).toHaveValue('2')
  const createButton = page.getByRole('button', { name: /医生确认并开立/ })
  await expect(createButton).toBeEnabled()
  const createResponse = page.waitForResponse((response) =>
    response.url().includes('/api/v1/pharmacy/prescription') && response.request().method() === 'POST',
  )
  await createButton.click()
  const createdResponse = await createResponse
  await expect(createdResponse.status()).toBe(200)
  const createdPayload = (await createdResponse.json()) as { code: number; data: { uuid: string } }
  expect(createdPayload.code).toBe(201)
  const prescriptionUuid = createdPayload.data.uuid
  await expect(page.locator('.doctor-encounter__prescription-created')).toBeVisible()

  const apiBaseUrl = process.env.E2E_API_BASE_URL ?? 'http://localhost:8000'
  const detailResult = await page.evaluate(async ({ baseUrl, uuid }) => {
    const response = await fetch(`${baseUrl}/api/v1/pharmacy/admin/workbench/prescriptions/${uuid}`)
    return { status: response.status, payload: await response.json() }
  }, { baseUrl: apiBaseUrl, uuid: prescriptionUuid })
  expect(detailResult.status).toBe(200)
  const detailPayload = detailResult.payload as {
    data: { header: { register_uuid: string; is_ai_recommended: boolean }; items: Array<{ drug_number: number }> }
  }
  expect(detailPayload.data.header.register_uuid).toBe(fixture.register_uuid)
  expect(detailPayload.data.header.is_ai_recommended).toBe(true)
  expect(detailPayload.data.items.length).toBeGreaterThan(0)
  expect(detailPayload.data.items[0].drug_number).toBe(2)
})

test('doctor encounter keeps the clinical workspace ahead of AI support on a narrow screen', async ({ page }) => {
  test.setTimeout(120_000)
  await page.setViewportSize({ width: 390, height: 844 })
  const fixture = createFixture()

  await page.goto('/doctor/login')
  const form = page.locator('.doctor-login__form')
  await expect(form).toBeVisible()
  await form.locator('select').nth(0).selectOption('XNK')
  await form.locator('select').nth(1).selectOption(fixture.doctor_uuid)
  await form.locator('button[type="button"]').click()
  await expect(page).toHaveURL(/\/doctor\/workbench/)

  await page.goto(fixture.encounter_url)
  const workspace = page.locator('.doctor-encounter__workspace')
  await expect(workspace).toBeVisible()
  const layout = await workspace.evaluate((element) => {
    const main = element.querySelector<HTMLElement>('.doctor-encounter__main')
    const sidebar = element.querySelector<HTMLElement>('.doctor-encounter__sidebar')
    if (!main || !sidebar) {
      throw new Error('Doctor encounter workspace is incomplete')
    }

    return {
      columns: getComputedStyle(element).gridTemplateColumns,
      mainTop: main.getBoundingClientRect().top,
      sidebarTop: sidebar.getBoundingClientRect().top,
      pageScrollWidth: document.documentElement.scrollWidth,
      pageClientWidth: document.documentElement.clientWidth,
    }
  })

  expect(layout.columns.trim().split(/\s+/)).toHaveLength(1)
  expect(layout.mainTop).toBeLessThan(layout.sidebarTop)
  expect(layout.pageScrollWidth).toBeLessThanOrEqual(layout.pageClientWidth + 1)
})
