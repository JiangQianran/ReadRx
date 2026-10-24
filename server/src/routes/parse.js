import { Router } from 'express';
import { config } from '../config.js';
import { chatJson } from '../deepseek.js';
import { parseSystemPrompt, parseUserText } from '../prompts.js';
import { normalizeParse } from '../normalize.js';
import { mockMedicine } from '../mock.js';

const router = Router();
const MAX_IMAGES = 6;

/**
 * POST /api/parse
 * body: { images: ["data:image/jpeg;base64,..." 或纯 base64 字符串, ...] }
 */
router.post('/', async (req, res, next) => {
  try {
    const images = Array.isArray(req.body?.images) ? req.body.images.filter((s) => typeof s === 'string' && s.length > 100) : [];
    if (images.length === 0) return res.status(400).json({ error: '请至少上传一张照片' });
    if (images.length > MAX_IMAGES) return res.status(400).json({ error: `一次最多上传 ${MAX_IMAGES} 张照片` });

    if (config.mock) return res.json({ ...mockMedicine, medicines: [mockMedicine] });

    const today = new Date().toLocaleDateString('sv-SE', { timeZone: 'Asia/Shanghai' });
    const content = [
      { type: 'text', text: parseUserText },
      ...images.map((img) => ({
        type: 'image_url',
        image_url: { url: img.startsWith('data:') ? img : `data:image/jpeg;base64,${img}` },
      })),
    ];

    const raw = await chatJson({
      model: config.visionModel,
      // 多种药时输出会长很多
      maxTokens: 8192,
      messages: [
        { role: 'system', content: parseSystemPrompt(today) },
        { role: 'user', content },
      ],
    });
    res.json(normalizeParse(raw));
  } catch (err) {
    next(err);
  }
});

export default router;
