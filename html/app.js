const $=s=>document.querySelector(s);
let AC = null;
function ac() { if (!AC) AC = new (window.AudioContext || window.webkitAudioContext)(); return AC; }
function tone(f, t0, dur, vol, type = 'sine', dest) {
  const a = ac(), o = a.createOscillator(), g = a.createGain();
  o.type = type; o.frequency.value = f;
  g.gain.setValueAtTime(0.0001, a.currentTime + t0);
  g.gain.exponentialRampToValueAtTime(vol, a.currentTime + t0 + 0.01);
  g.gain.exponentialRampToValueAtTime(0.0001, a.currentTime + t0 + dur);
  o.connect(g); g.connect(dest || a.destination); o.start(a.currentTime + t0); o.stop(a.currentTime + t0 + dur + 0.05);
}
const SOUNDS = {
  chime(v) {   // classic two-tone "ding-dong" with bell harmonics
    [[659.25, 0], [523.25, 0.55]].forEach(([f, t]) => {
      tone(f, t, 1.8, 0.5 * v); tone(f * 2, t, 1.0, 0.12 * v); tone(f * 3.01, t, 0.6, 0.05 * v, 'triangle');
    });
  },
  alert(v) { tone(880, 0, 0.15, 0.25 * v); tone(1320, 0.14, 0.25, 0.22 * v); },
  talk(v) { tone(1000, 0, 0.08, 0.2 * v, 'square'); tone(1400, 0.09, 0.08, 0.15 * v, 'square'); },
  shutter() { const a = ac(), n = a.sampleRate * 0.12, b = a.createBuffer(1, n, a.sampleRate), d = b.getChannelData(0);
    for (let i = 0; i < n; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / n, 3);
    const s = a.createBufferSource(); s.buffer = b; const g = a.createGain(); g.gain.value = 0.35; s.connect(g); g.connect(a.destination); s.start(); },
  siren(v, dur = 8000) {
    const a = ac(), o = a.createOscillator(), g = a.createGain(), l = a.createOscillator(), lg = a.createGain();
    o.type = 'sawtooth'; o.frequency.value = 900; l.frequency.value = 2.2; lg.gain.value = 350;
    l.connect(lg); lg.connect(o.frequency); g.gain.value = 0.18 * v;
    o.connect(g); g.connect(a.destination); o.start(); l.start();
    g.gain.setValueAtTime(0.18 * v, a.currentTime + dur / 1000 - 0.2); g.gain.linearRampToValueAtTime(0, a.currentTime + dur / 1000);
    o.stop(a.currentTime + dur / 1000 + 0.05); l.stop(a.currentTime + dur / 1000 + 0.05);
  },
};


window.addEventListener('message',e=>{const {action,data}=e.data||{}; if(!data)return; if(action==='sound' && SOUNDS[data.name]){const a=ac(); if(a.state==='suspended')a.resume().catch(()=>{}); SOUNDS[data.name](data.volume??1,data.duration);} if(action==='install'){ $('#install').classList.toggle('hidden',!data.show); if(data.show){$('#ins-finish').textContent=data.finish; $('#ins-state').textContent=data.valid?'Ready — press ENTER to install':'Aim at a wall within reach';}}});
