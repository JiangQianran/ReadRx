/** 对模型输出做兜底整理，保证 App 拿到的字段类型稳定 */

const str = (v) => (v === null || v === undefined ? '' : String(v).trim());
const arr = (v) => (Array.isArray(v) ? v.map(str).filter(Boolean) : v ? [str(v)] : []);

function normDate(v) {
  const s = str(v);
  const m = s.match(/^(\d{4})[-./年](\d{1,2})(?:[-./月](\d{1,2}))?/);
  if (!m) return null;
  const y = Number(m[1]);
  const mo = Number(m[2]);
  if (mo < 1 || mo > 12) return null;
  // 只到月份时，取当月最后一天
  const d = m[3] ? Number(m[3]) : new Date(Date.UTC(y, mo, 0)).getUTCDate();
  return `${y}-${String(mo).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
}

const AI_FILLABLE = ['usage', 'indications', 'sideEffects', 'contraindications', 'cautions', 'simpleSummary'];

export function normalizeMedicine(raw = {}) {
  const usage = raw.usage || {};
  const expiry = raw.expiry || {};
  return {
    aiFilled: arr(raw.aiFilled).filter((k) => AI_FILLABLE.includes(k)),
    recognized: raw.recognized !== false,
    name: str(raw.name),
    genericName: str(raw.genericName),
    manufacturer: str(raw.manufacturer),
    specification: str(raw.specification),
    expiry: { raw: str(expiry.raw), date: normDate(expiry.date), note: str(expiry.note) },
    usage: {
      frequency: str(usage.frequency),
      amount: str(usage.amount),
      method: str(usage.method),
      notes: str(usage.notes),
    },
    indications: str(raw.indications),
    sideEffects: arr(raw.sideEffects),
    contraindications: arr(raw.contraindications),
    cautions: arr(raw.cautions),
    simpleSummary: str(raw.simpleSummary),
    speechText: str(raw.speechText),
    missing: arr(raw.missing),
  };
}

/**
 * 识别结果：照片里可能有多种药。
 * 返回 { medicines: [...] }，同时把第一种药的字段铺在顶层，兼容只认单个药品的旧版 App。
 */
export function normalizeParse(raw = {}) {
  const list = Array.isArray(raw.medicines) ? raw.medicines : raw.name || raw.genericName ? [raw] : [];
  const medicines = list
    .filter((m) => m && typeof m === 'object')
    .map(normalizeMedicine)
    .filter((m) => m.recognized && (m.name || m.genericName));
  const first = medicines[0] ?? normalizeMedicine({ recognized: false });
  return { ...first, recognized: medicines.length > 0, medicines };
}

const LEVELS = ['禁止', '慎用', '不确定', '无明显风险'];

export function normalizeInteraction(raw = {}) {
  const results = (Array.isArray(raw.results) ? raw.results : [])
    .map((r) => ({
      a: str(r?.a),
      b: str(r?.b),
      level: LEVELS.includes(str(r?.level)) ? str(r.level) : '不确定',
      reason: str(r?.reason),
      advice: str(r?.advice),
    }))
    .filter((r) => r.a || r.b)
    // 危险的排前面
    .sort((x, y) => LEVELS.indexOf(x.level) - LEVELS.indexOf(y.level));

  return {
    normalized: (Array.isArray(raw.normalized) ? raw.normalized : []).map((n) => ({
      input: str(n?.input),
      name: str(n?.name),
      type: ['drug', 'food', 'unknown'].includes(str(n?.type)) ? str(n.type) : 'unknown',
    })),
    results,
    summary: str(raw.summary),
    speechText: str(raw.speechText) || str(raw.summary),
  };
}
