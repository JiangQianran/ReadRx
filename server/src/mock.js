/** 演示模式下返回的示例数据（未配置 API Key 时使用） */

export const mockMedicine = {
  recognized: true,
  name: '泰诺',
  genericName: '对乙酰氨基酚缓释片',
  manufacturer: '示例制药有限公司',
  specification: '0.65g×18片',
  expiry: { raw: '有效期至 2027.05', date: '2027-05-31', note: '' },
  usage: {
    frequency: '每8小时1次，24小时内不超过3次',
    amount: '每次1至2片',
    method: '口服，整片吞服，不要嚼碎',
    notes: '用于解热连续使用不超过3天，用于止痛不超过5天',
  },
  indications: '用于普通感冒或流感引起的发热，也用于缓解轻至中度疼痛',
  sideEffects: ['偶见恶心、呕吐、出汗、腹痛', '少数人出现皮疹'],
  contraindications: ['对本品过敏者禁用', '严重肝肾功能不全者禁用'],
  cautions: ['服药期间不要喝酒', '不要同时服用其他含对乙酰氨基酚的感冒药'],
  simpleSummary:
    '这是退烧止痛药。发烧或头疼牙疼时吃，每次一到两片，八小时吃一次，一天最多三次。吃药期间别喝酒，也别和别的感冒药一起吃。',
  speechText:
    '这是泰诺，对乙酰氨基酚缓释片，有效期到二零二七年五月。用于退烧和止痛。每次吃一到两片，每八小时一次，一天不超过三次，整片吞下不要嚼。可能有恶心、出汗等副作用。吃药期间不要喝酒，不要和其他感冒药一起吃。',
  aiFilled: [],
  missing: [],
  mock: true,
};

export function mockInteraction({ drugs, foods }) {
  const a = drugs[0] || '对乙酰氨基酚';
  const b = drugs[1] || foods[0] || '酒精';
  return {
    normalized: [...drugs.map((d) => ({ input: d, name: d, type: 'drug' })), ...foods.map((f) => ({ input: f, name: f, type: 'food' }))],
    results: [
      { a, b, level: '慎用', reason: '这是演示数据，不是真实结论。', advice: '配置 DeepSeek API Key 后可获得真实结果。' },
      { a: '对乙酰氨基酚', b: '酒精', level: '禁止', reason: '两者都会伤肝，同时使用可能造成严重肝损伤。', advice: '吃药期间和停药后三天内不要喝酒。' },
    ],
    summary: '（演示数据）对乙酰氨基酚不能和酒一起吃。',
    speechText: '这是演示数据。对乙酰氨基酚不能和酒一起吃，会伤肝。',
    mock: true,
  };
}
