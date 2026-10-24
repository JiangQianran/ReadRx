import os from 'node:os';
import express from 'express';
import cors from 'cors';
import { rateLimit } from 'express-rate-limit';
import { config } from './config.js';
import parseRouter from './routes/parse.js';
import interactionRouter from './routes/interaction.js';

const app = express();
app.use(cors());
app.use(express.json({ limit: '40mb' }));

// 健康检查：App 设置页里的「测试连接」会调用它
app.get('/api/health', (req, res) => {
  res.json({ ok: true, mock: config.mock, needToken: Boolean(config.appToken) });
});

// 可选的访问口令
app.use('/api', (req, res, next) => {
  if (!config.appToken || req.get('x-app-token') === config.appToken) return next();
  res.status(401).json({ error: '访问口令不正确，请在 App 设置中检查' });
});

// 防止被刷：每个 IP 每分钟最多 20 次
app.use('/api', rateLimit({ windowMs: 60_000, limit: 20, message: { error: '请求太频繁，请稍后再试' } }));

app.use('/api/parse', parseRouter);
app.use('/api/interaction', interactionRouter);

app.use((req, res) => res.status(404).json({ error: '接口不存在' }));

// 统一错误处理：把 DeepSeek 的错误翻译成用户看得懂的话
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('[error]', err?.status || '', err?.message || err);
  if (err?.type === 'entity.too.large') return res.status(413).json({ error: '照片太大，请少传几张或重新拍摄' });
  const status = err?.status;
  let msg = 'AI 服务暂时不可用，请稍后再试';
  if (status === 401) msg = '服务器的 DeepSeek API Key 无效';
  else if (status === 402) msg = 'DeepSeek 账户余额不足';
  else if (status === 429) msg = 'AI 服务繁忙，请稍后再试';
  else if (status === 400) msg = 'AI 无法处理这次请求，请换张清晰的照片再试';
  else if (err instanceof SyntaxError || /JSON/.test(err?.message || '')) msg = 'AI 返回的结果格式有误，请重试';
  res.status(502).json({ error: msg });
});

app.listen(config.port, '0.0.0.0', () => {
  console.log(`ReadRx 后端已启动，端口 ${config.port}`);
  if (config.mock) console.log('⚠ 当前为演示模式（未配置 DeepSeek API Key 或设置了 MOCK=1），返回的是示例数据');
  console.log(`识图模型：${config.visionModel}，文本模型：${config.textModel}，思考模式：${config.thinking ? '开' : '关'}`);
  console.log('在 App 设置里填写下面任一地址（手机和电脑需在同一 Wi-Fi）：');
  for (const list of Object.values(os.networkInterfaces())) {
    for (const n of list || []) {
      if (n.family === 'IPv4' && !n.internal) console.log(`  http://${n.address}:${config.port}`);
    }
  }
  console.log(`  安卓模拟器用：http://10.0.2.2:${config.port}`);
});
