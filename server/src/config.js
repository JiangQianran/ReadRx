import dotenv from 'dotenv';

dotenv.config({ quiet: true });

const apiKey = (process.env.DEEPSEEK_API_KEY || '').trim();
const forceMock = process.env.MOCK === '1' || process.argv.includes('--mock');

export const config = {
  port: Number(process.env.PORT) || 3000,
  apiKey,
  baseURL: process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com',
  visionModel: process.env.DEEPSEEK_VISION_MODEL || 'deepseek-flash',
  textModel: process.env.DEEPSEEK_TEXT_MODEL || 'deepseek-flash',
  // 思考模式：更仔细但慢一倍以上，默认关闭
  thinking: process.env.DEEPSEEK_THINKING === '1',
  appToken: (process.env.APP_TOKEN || '').trim(),
  // 没有 Key 时自动进入演示模式，方便先把 App 跑通
  mock: forceMock || !apiKey,
};
