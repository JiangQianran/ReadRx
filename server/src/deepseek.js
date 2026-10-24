import OpenAI from 'openai';
import { config } from './config.js';

let client = null;

function getClient() {
  if (!client) {
    client = new OpenAI({ apiKey: config.apiKey, baseURL: config.baseURL, timeout: 90_000 });
  }
  return client;
}

/** 从模型输出中取出 JSON（兼容 ```json 代码块等情况） */
export function extractJson(text) {
  if (!text) throw new Error('模型没有返回内容');
  const cleaned = text.replace(/```(?:json)?/gi, '').trim();
  try {
    return JSON.parse(cleaned);
  } catch {
    const start = cleaned.indexOf('{');
    const end = cleaned.lastIndexOf('}');
    if (start >= 0 && end > start) return JSON.parse(cleaned.slice(start, end + 1));
    throw new Error('模型返回的不是有效 JSON');
  }
}

/**
 * 调用 DeepSeek，要求返回 JSON。
 * 优先使用 response_format=json_object；如果接口不支持（例如带图片时），自动退回普通模式再解析。
 */
export async function chatJson({ model, messages, temperature = 0, maxTokens = 4096 }) {
  const base = {
    model,
    messages,
    temperature,
    max_tokens: maxTokens,
    thinking: { type: config.thinking ? 'enabled' : 'disabled' },
  };
  let completion;
  try {
    completion = await getClient().chat.completions.create({
      ...base,
      response_format: { type: 'json_object' },
    });
  } catch (err) {
    if (err?.status === 400) {
      completion = await getClient().chat.completions.create(base);
    } else {
      throw err;
    }
  }
  return extractJson(completion.choices?.[0]?.message?.content);
}
