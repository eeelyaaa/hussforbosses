"""M2-26 economy model: the same player policy as studio/checks/Curves.lua phase c, with Power gating.
Run: python tools/econ_model.py [seeds] [mixPerRing] [rMax] [half]  (M2-26; verification/m2-26-curves.md)"""
import math, random, sys

RING = [1.05, .98, .91, .84, .77, .70, .63, .56, .48, .41]
BURST = 0.61
SCOST = [0,150,400,900,1800,3200,5800,10000,19000,34000,61000,110000,200000,360000,640000,1.2e6,2.1e6,3.7e6,6.7e6,12e6,
         22e6,39e6,71e6,130e6,230e6,410e6,740e6,1.3e9,2.4e9,4.3e9]
VCOST = [0,100,400,1600,6500,26000,100000,400000,1.6e6,6.5e6]
PM = [1,1.6,2.6,4,6,9]; IM = [1,2,4,8,20,60]
ZP = [25*10**(z) for z in range(6)]
ZI = [1,8,60,450,3500,28000]
ODDS = [[50,28,14,6,1.7,.3],[46,28,15,8,2.5,.5],[42,28,16,10,3.3,.7],[38,27,18,12,4,1],[34,26,20,13,5.5,1.5],[30,25,21,15,7,2]]
def power(z,t): return round(ZP[z]*PM[t]) if z < 2 else ZP[z]*PM[t]
POW = {(z,t): [25,40,65,100,150,225][t]*10**z for z in range(6) for t in range(6)}
INC = {(z,t): [[1,2,4,8,20,60],[8,16,32,64,160,480],[60,120,240,480,1200,3600],[450,900,1800,3600,9000,27000],
               [3500,7000,14000,28000,70000,210000],[28000,56000,112000,224000,560000,1680000]][z][t] for z in range(6) for t in range(6)}
def upcost(z,t,L): return round(30*INC[(z,t)]*1.3**(L-1))
def inc(b): return INC[b['c']]*(1+0.25*(b['L']-1))

def run(seed, mix=5.5, rmax=1.0, payback=600, log=False, T=1800, half=False):
    rnd = random.Random(seed)
    t = 0.0; P = 0.0; cash = 0.0; S = 1; V = 1
    bosses = []  # {c, L, stamp, pad}
    rolls = {}   # (z,k) -> (rollIndex, tier)
    beaten = set()
    marks = {}; events = {}
    def roll(z,k,now):
        idx = int((now + k*15) // 45)
        if (z,k,idx) not in rolls:
            r = rnd.random()*100; acc = 0
            for ti,o in enumerate(ODDS[z]):
                acc += o
                if r < acc: break
            rolls[(z,k,idx)] = ti
        return idx, rolls[(z,k,idx)]
    def rate(): return sum(inc(b) for b in bosses)
    def advance(dt, bag):
        nonlocal t, P
        steps = int(dt)
        for _ in range(max(steps,1) if dt>=1 else 0):
            for m in (180,600,1800):
                if m not in marks and t >= m: marks[m] = (rate(), len(bosses), cash, P, S, V)
            t += 1
            for b in bosses: b['pad'] += inc(b)
            if bag: P += mix/(RING[V-1]+BURST)*1.35**(S-1)
        frac = dt - steps if dt>=1 else dt
        t += frac
        if bag: P += mix/(RING[V-1]+BURST)*1.35**(S-1)*frac
        for b in bosses: b['pad'] += inc(b)*frac
    def atBase():
        nonlocal cash, S, V
        for b in bosses: cash += b['pad']; b['pad'] = 0
        if 'FirstCashCollected' not in events and cash > 0: events['FirstCashCollected'] = t
        bought = True
        while bought:
            bought = False
            # cheapest-payback upgrade under payback
            best=None
            for b in bosses:
                if b['L'] >= 20: continue
                c = upcost(*b['c'], b['L']); g = INC[b['c']]*0.25
                if c/g <= payback and c <= cash and (best is None or c/g < best[0]): best = (c/g, c, b)
            sc = SCOST[S] if S < 30 else None
            vc = VCOST[V] if V < 10 else None
            # Strength when affordable (it gates zones), Speed when it costs no more than the next Strength
            if sc is not None and cash >= sc and (best is None or sc <= best[1]*4):
                cash -= sc; S += 1; bought = True
                events.setdefault('FirstStrengthBought', t); continue
            if vc is not None and cash >= vc and (sc is None or vc <= sc):
                cash -= vc; V += 1; bought = True; continue
            if best:
                cash -= best[1]; best[2]['L'] += 1; bought = True
                events.setdefault('FirstBossUpgraded', t)
    def fightTime(r):
        need = 10*r
        taps = math.ceil(need/mix)
        return RING[V-1] + (taps-1)*(RING[V-1]+BURST) + 0.4
    first = True
    bagT = 0.0; tripT = 0.0
    while t < T:
        if half and P >= 25 and bagT < tripT:
            advance(5, True); bagT += 5; atBase(); continue
        # candidates: every pad, green (r <= rmax), not beaten this roll, worth placing
        low = min(bosses, key=inc) if len(bosses) >= 10 else None
        best=None
        for z in range(6):
            for k in range(4):
                if k == 0: idx, ti = ('f', int(t//1e9)), 0
                else: idx, ti = roll(z,k,t)
                key = (z,k,idx)
                if key in beaten: continue
                c = (z,ti)
                if P <= 0 or POW[c]/P > rmax: continue
                d = 200 + 120*z + 20*k
                trip = d/16 + fightTime(POW[c]/P) + d/12 + 4
                gain = INC[c] - (inc(low) if low else 0)
                if gain <= 0: continue
                score = gain/trip
                if best is None or score > best[0]: best = (score, c, key, d, trip, POW[c]/P)
        if best is None:
            advance(5, True); bagT += 5  # train at the bag, collect and buy every 5 s
            atBase(); continue
        _, c, key, d, trip, r = best
        if first: events['FirstFightStarted'] = t + d/16
        advance(trip, False); tripT += trip
        if key[1] != 0: beaten.add(key)
        if low: cash += 20*inc(low); bosses.remove(low)
        bosses.append({'c': c, 'L': 1, 'pad': 0})
        if first: events['FirstBossPlaced'] = t; first = False
        if c[0] == 1 and 'Zone2BossPlaced' not in events: events['Zone2BossPlaced'] = t
        if c[0] == 2 and 'Zone3BossPlaced' not in events: events['Zone3BossPlaced'] = t
        if c[0] == 3 and 'Zone4BossPlaced' not in events: events['Zone4BossPlaced'] = t
        if log: print(f"{t:7.0f} placed z{c[0]+1}t{c[1]+1} r={r:.2f} P={P:.0f} S{S} V{V} rate={rate():.1f}")
        # the player then trains at the bag briefly (first a short stop so the base is visited)
        atBase()
    for m in (180,600,1800):
        if m not in marks: marks[m] = (rate(), len(bosses), cash, P, S, V)
    return marks, events, P, S, V

if __name__ == '__main__':
    seeds = int(sys.argv[1]) if len(sys.argv) > 1 else 20
    mix = float(sys.argv[2]) if len(sys.argv) > 2 else 5.5
    rmax = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
    half = len(sys.argv) > 4 and sys.argv[4] == 'half'
    res = [run(s, mix, rmax, half=half) for s in range(seeds)]
    for m in (180,600,1800):
        v = sorted(r[0][m][0] for r in res)
        print(f"min {m//60}: income median {v[len(v)//2]:.1f} range {v[0]:.1f}-{v[-1]:.1f}  power med {sorted(r[0][m][3] for r in res)[len(v)//2]:.0f} S med {sorted(r[0][m][4] for r in res)[len(v)//2]}")
    for e in ('FirstFightStarted','FirstBossPlaced','FirstCashCollected','FirstBossUpgraded','FirstStrengthBought','Zone2BossPlaced','Zone3BossPlaced','Zone4BossPlaced'):
        v = sorted(r[1].get(e, 9e9) for r in res)
        print(f"{e}: median {v[len(v)//2]:.0f}s range {v[0]:.0f}-{v[-1]:.0f}")
    run(0, mix, rmax, log=True, T=700, half=half)
