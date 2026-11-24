// uso: node render.mjs stills <t1,t2,...> <pastaSaida>
//      node render.mjs video <audio.wav> <saida.mp4> <poster.jpg> <tempoDoPoster>
import puppeteer from './node/node_modules/puppeteer-core/lib/puppeteer/puppeteer-core.js';
import {spawn} from 'node:child_process';
import path from 'node:path';
import fs from 'node:fs';
import {fileURLToPath, pathToFileURL} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const FPS = 30, TOTAL = 76;
const browser = await puppeteer.launch({
  executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  headless: true,
  args: ['--hide-scrollbars', '--force-device-scale-factor=1', '--allow-file-access-from-files'],
});
const page = await browser.newPage();
await page.setViewport({width: 1920, height: 1080, deviceScaleFactor: 1});
await page.goto(pathToFileURL(path.join(here, 'video.html')).href);
await page.evaluate(() => window.ready);

const mode = process.argv[2];
if (mode === 'stills') {
  const ts = process.argv[3].split(',').map(Number);
  const out = process.argv[4];
  fs.mkdirSync(out, {recursive: true});
  for (const t of ts) {
    await page.evaluate(t => window.render(t), t);
    await page.screenshot({path: path.join(out, `t${t.toFixed(2).padStart(6, '0')}.png`)});
  }
} else {
  const [audio, outMp4, poster, pt] = process.argv.slice(3);
  const n = TOTAL * FPS;
  const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'mjpeg', '-i', '-',
    '-i', audio, '-map', '0:v', '-map', '1:a', '-c:v', 'libx264', '-preset', 'slow', '-crf', '16', '-pix_fmt', 'yuv420p',
    '-r', String(FPS), '-c:a', 'aac', '-b:a', '192k', '-shortest', '-movflags', '+faststart', outMp4], {stdio: ['pipe', 'inherit', 'inherit']});
  for (let i = 0; i < n; i++) {
    // quadro 0 = poster (melhor quadro assentado), no lugar do quadro vazio
    const t = i === 0 ? Number(pt) : i / FPS;
    await page.evaluate(t => window.render(t), t);
    const buf = await page.screenshot({type: 'jpeg', quality: 95});
    if (i === 0) await page.screenshot({path: poster, type: 'jpeg', quality: 95});
    if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
    if (i % 150 === 0) console.log('frame', i, '/', n);
  }
  ff.stdin.end();
  await new Promise(r => ff.on('close', r));
}
await browser.close();
