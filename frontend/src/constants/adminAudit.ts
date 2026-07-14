export const AUDIT_MODULE_OPTIONS = [
  { value: 'patient.triage', label: '患者 AI 分诊' },
  { value: 'patient.scheduling', label: 'AI 排班微调' },
  { value: 'medical.draft', label: '病历初稿生成' },
  { value: 'pharmacy.prescription', label: 'AI 处方推荐' },
  { value: 'medical.agent', label: '医生智能助理' },
  { value: 'embedding', label: '向量嵌入' },
] as const

export const AUDIT_SOURCE_OPTIONS = [
  { value: 'llm', label: '真实 LLM' },
  { value: 'rule', label: '规则引擎' },
  { value: 'fallback', label: '降级兜底' },
  { value: 'mock', label: '模拟引擎' },
  { value: 'embedding', label: '向量模型' },
  { value: 'ocr', label: 'OCR' },
  { value: 'asr', label: 'ASR' },
  { value: 'image_model', label: '图像模型' },
] as const

const MODULE_LABEL_MAP = Object.fromEntries(AUDIT_MODULE_OPTIONS.map((item) => [item.value, item.label]))
const SOURCE_LABEL_MAP = Object.fromEntries(AUDIT_SOURCE_OPTIONS.map((item) => [item.value, item.label]))

export function auditModuleLabel(moduleName?: string | null) {
  return moduleName ? MODULE_LABEL_MAP[moduleName] || moduleName : '未知模块'
}

export function auditSourceLabel(source?: string | null) {
  return source ? SOURCE_LABEL_MAP[source] || source : '未知来源'
}
