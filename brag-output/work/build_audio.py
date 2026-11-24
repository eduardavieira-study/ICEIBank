"""Trilha do video: 120 bpm, La menor (Am-F-C-G), 76 s. Tudo na mesma grade de 16avos (0,125 s).
Uso: python3 -I build_audio.py saida.wav"""
import math, random, struct, sys, array

SR = 44100
TOTAL = 76.0
BPM = 120
BEAT = 60.0 / BPM          # 0,5 s
BAR = BEAT * 4             # 2 s
N = int(SR * TOTAL)
random.seed(7)
L = [0.0] * N              # mono; espelhado nos dois canais no fim


def add(t0, samples, gain=1.0):
    i0 = int(t0 * SR)
    for k, v in enumerate(samples):
        i = i0 + k
        if 0 <= i < N:
            L[i] += v * gain


def env_exp(n, attack, decay):
    return [min(1.0, k / (attack * SR)) * math.exp(-k / (decay * SR)) for k in range(n)]


def quant(t, grid=BEAT / 2):   # SFX caem no 8avo mais proximo
    return round(t / grid) * grid


# progressao: Am F C G (uma por compasso)
CH = [
    dict(root=110.00, tones=[220.00, 261.63, 329.63]),
    dict(root=87.31, tones=[174.61, 220.00, 261.63]),
    dict(root=130.81, tones=[261.63, 329.63, 392.00]),
    dict(root=98.00, tones=[196.00, 246.94, 293.66]),
]
NBARS = int(TOTAL / BAR)  # 38

# ---------- pad (com ducking) ----------
pad = [0.0] * N
for b in range(NBARS):
    c = CH[b % 4]
    n = int(BAR * SR) + int(0.3 * SR)
    seg = [0.0] * n
    for f in c['tones']:
        for det in (-0.6, 0.6):
            w = 2 * math.pi * (f + det) / SR
            for k in range(n):
                seg[k] += math.sin(w * k)
    for k in range(n):
        a = min(1.0, k / (0.35 * SR))
        r = min(1.0, (n - k) / (0.3 * SR))
        seg[k] *= a * r * 0.035
    i0 = int(b * BAR * SR)
    for k in range(n):
        if i0 + k < N:
            pad[i0 + k] += seg[k]
for i in range(N):
    t = i / SR
    ph = (t % BEAT)
    duck = 1.0 - 0.4 * math.exp(-ph / 0.16) if t >= BAR else 1.0
    L[i] += pad[i] * duck

# ---------- baixo (a partir de 4 s) ----------
for b in range(2, NBARS - 1):
    c = CH[b % 4]
    for beat in range(8):          # colcheias
        t0 = b * BAR + beat * BEAT / 2
        f = c['root'] * (2 if beat % 4 == 3 else 1)
        n = int(0.32 * SR)
        e = env_exp(n, 0.006, 0.13)
        w = 2 * math.pi * f / SR
        add(t0, [math.sin(w * k) * e[k] * 0.20 + math.sin(2 * w * k) * e[k] * 0.04 for k in range(n)])

# ---------- pluck arpejo (a partir de 2 s; mais suave no inicio) ----------
for b in range(1, NBARS - 1):
    c = CH[b % 4]
    seq = [0, 1, 2, 1, 0, 1, 2, 1]
    for s in range(8):
        t0 = b * BAR + s * BEAT / 2
        f = c['tones'][seq[s]] * 2
        n = int(0.28 * SR)
        e = env_exp(n, 0.003, 0.09)
        w = 2 * math.pi * f / SR
        g = 0.045 if b < 2 else 0.07
        add(t0, [(math.sin(w * k) + 0.3 * math.sin(2 * w * k)) * e[k] * g for k in range(n)])

# ---------- kick (de 2 s ate 74 s), hat, clap ----------
for bt in range(int(BAR / BEAT), int(74 / BEAT)):
    t0 = bt * BEAT
    n = int(0.28 * SR)
    ph = 0.0
    out = []
    for k in range(n):
        f = 42 + 90 * math.exp(-k / (0.035 * SR))
        ph += 2 * math.pi * f / SR
        out.append(math.sin(ph) * math.exp(-k / (0.09 * SR)) * 0.55)
    add(t0, out)
for s in range(int(BAR / (BEAT / 2)), int(74 / (BEAT / 2))):   # hat nas contratempos
    if s % 2 == 1:
        t0 = s * BEAT / 2
        n = int(0.05 * SR)
        prev = 0.0
        out = []
        for k in range(n):
            x = random.uniform(-1, 1)
            hp = x - prev
            prev = x
            out.append(hp * math.exp(-k / (0.012 * SR)) * 0.07)
        add(t0, out)
for bt in range(int(2 * BAR / BEAT), int(74 / BEAT)):      # clap nos tempos 2 e 4, de 4 s em diante
    if bt % 4 in (1, 3):
        t0 = bt * BEAT
        n = int(0.14 * SR)
        prev = 0.0
        out = []
        for k in range(n):
            x = random.uniform(-1, 1)
            lp = prev + 0.35 * (x - prev)
            prev = lp
            out.append(lp * math.exp(-k / (0.04 * SR)) * 0.16)
        add(t0, out)

# ---------- SFX: notas da escala de La menor, suaves ----------
def bell(t, f, gain=0.10, dec=0.35):
    n = int(dec * 4 * SR)
    e = env_exp(n, 0.002, dec)
    w = 2 * math.pi * f / SR
    add(quant(t), [(math.sin(w * k) + 0.25 * math.sin(2.01 * w * k)) * e[k] * gain for k in range(n)])

def tick(t, f, gain=0.07):
    bell(t, f, gain, 0.10)

def low(t, f=110.0, gain=0.14):   # tom grave para erro/queda
    n = int(0.5 * SR)
    e = env_exp(n, 0.004, 0.18)
    w = 2 * math.pi * f / SR
    add(quant(t), [math.sin(w * k) * e[k] * gain + math.sin(1.5 * w * k) * e[k] * gain * .4 for k in range(n)])

def swoosh(t_end, dur=0.5, gain=0.05):   # ruido filtrado subindo, termina no corte
    n = int(dur * SR)
    prev = 0.0
    out = []
    for k in range(n):
        x = random.uniform(-1, 1)
        a = 0.02 + 0.5 * (k / n) ** 2
        prev = prev + a * (x - prev)
        out.append(prev * (k / n) ** 1.5 * gain * 4)
    add(t_end - dur, out)

A5, E5, G5, C5, D5, A4, E4, C6, E6 = 880.0, 659.25, 783.99, 523.25, 587.33, 440.0, 329.63, 1046.5, 1318.5
for t in (4, 16, 28, 40, 50, 64, 70):
    swoosh(t)
    bell(t, A5, 0.09, 0.4)

# S1 gancho
tick(1.0, A4); tick(1.25, C5); tick(1.5, E5)
bell(2.0, E5, 0.06)
# S2 pub/sub (inicio 4 s)
tick(6.2, G5, 0.08); tick(7.4, E5, 0.08); low(7.8, 110); bell(11.0, C6, 0.07); bell(12.3, E6, 0.07, 0.3)
# S3 vetorial (16 s)
tick(19.0, C5); tick(19.4, E5); tick(19.8, G5); bell(20.4, C6, 0.08, 0.4)
tick(22.6, A4); tick(23.0, D5); tick(23.4, E4); low(24.0, 98, 0.10)
# S4 bully (28 s)
bell(30.0, A4, 0.08, 0.25); bell(30.8, C5, 0.08, 0.25); bell(31.6, E5, 0.09, 0.3)
for t in (32.2, 33.4):
    low(t, 70, 0.10)
low(34.0, 82, 0.14)
bell(35.5, C5, 0.07, 0.25); bell(35.9, G5, 0.08, 0.35)
# S5 app (40 s)
tick(40.2, C5, 0.08)
for t in (41.4, 42.4, 43.4, 44.4):
    tick(t, E5)
# S6 offline (50 s)
tick(51.1, A4, 0.09); tick(54.7, C5, 0.09); tick(58.4, E5, 0.09); low(58.4, 98, 0.08)
# S7 extras (64 s)
for k, t in enumerate((64.6, 65.1, 65.6, 66.1)):
    tick(t, (A4, C5, E5, G5)[k])
# S8 fechamento (70 s)
bell(70.3, E5, 0.07); bell(73.4, A5, 0.10, 0.6); bell(73.4, E6, 0.05, 0.6)

# ---------- masterizacao ----------
peak = max(abs(v) for v in L) or 1.0
g = 0.85 / peak
fade_n = int(2.0 * SR)
for i in range(N):
    v = L[i] * g
    if i > N - fade_n:
        v *= (N - i) / fade_n
    L[i] = max(-1.0, min(1.0, math.tanh(v * 1.15)))

pcm = array.array('h')
for v in L:
    s = int(v * 32000)
    pcm.append(s)
    pcm.append(s)
out = sys.argv[1]
with open(out, 'wb') as f:
    data = pcm.tobytes()
    f.write(b'RIFF' + struct.pack('<I', 36 + len(data)) + b'WAVEfmt ' + struct.pack('<IHHIIHH', 16, 1, 2, SR, SR * 4, 4, 16) + b'data' + struct.pack('<I', len(data)))
    f.write(data)
print('ok', len(pcm) // 2 / SR, 's')
