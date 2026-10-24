import { Router } from 'express';
import { config } from '../config.js';
import { chatJson } from '../deepseek.js';
import { interactionSystemPrompt, interactionUserText } from '../prompts.js';
import { normalizeInteraction } from '../normalize.js';
import { mockInteraction } from '../mock.js';

const router = Router();

// 简单的内存缓存：同样的组合返回同样的答案，也更省钱。重启服务后清空。
const cache = new Map();
const CACHE_MAX = 500;

const cleanList = (v) =>
  (Array.isArray(v) ? v : [])
    .map((s) => String(s ?? '').trim())
    .filter(Boolean)
    .slice(0, 10);

/**
 * POST /api/interaction
 * body: { drugs: ["阿莫西林", ...], foods: ["白酒", ...], question?: "..." }
 */
router.post('/', async (req, res, next) => {
  try {
    const drugs = cleanList(req.body?.drugs);
    const foods = cleanList(req.body?.foods);
    const question = String(req.body?.question ?? '').trim().slice(0, 200);
    if (drugs.length === 0) return res.status(400).json({ error: '请至少填写一种药' });

    if (config.mock) return res.json(mockInteraction({ drugs, foods }));

    const key = JSON.stringify([[...drugs].sort(), [...foods].sort(), question]);
    if (cache.has(key)) return res.json({ ...cache.get(key), cached: true });

    const raw = await chatJson({
      model: config.textModel,
      messages: [
        { role: 'system', content: interactionSystemPrompt() },
        { role: 'user', content: interactionUserText({ drugs, foods, question }) },
      ],
    });
    const result = normalizeInteraction(raw);

    if (cache.size >= CACHE_MAX) cache.delete(cache.keys().next().value);
    cache.set(key, result);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;
