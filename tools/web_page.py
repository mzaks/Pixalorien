#!/usr/bin/env python3
"""Pixalorien's page around the web build (tools/build_web.sh).

`ent build --web` writes a plain page: a black canvas in the middle and
"Downloading data... (n/m)" in a corner while the 7 MB of pictures,
fonts and music come. This puts the game's own loading screen over it,
in the colours of the site (docs/index.html): the icon, the name, a bar
filled as the data comes, then the game faded in once it draws. Where
the program stops, the screen says so, above what it printed.

    tools/web_page.py PAGE            rewrites PAGE (index.html) in place

The icon and the font go beside the page (loading/), so the folder is
whole by itself (GitHub Pages, itch.io).
"""
import sys

STYLE = """<style>
@font-face{font-family:Jersey10;src:url(loading/Jersey10-Regular.ttf) format("truetype");font-display:swap}
html,body{background:#140a05}
canvas{background:#140a05;opacity:0;transition:opacity .5s}
body.ready canvas{opacity:1}
#output{z-index:3}
#status{display:none}
#splash{position:fixed;inset:0;z-index:2;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:14px;
 padding:24px;text-align:center;color:#f7e8d5;
 background:radial-gradient(ellipse at 50% 38%,#4a2510 0%,#24110a 45%,#140a05 80%);
 transition:opacity .6s,visibility .6s}
body.ready #splash{opacity:0;visibility:hidden}
#splash img{width:96px;height:96px;border-radius:22px;box-shadow:0 10px 40px rgba(232,135,63,.35);animation:bob 2.4s ease-in-out infinite}
#splash h1{margin:6px 0 0;font:normal 56px/1 Jersey10,"Courier New",monospace;letter-spacing:.04em;color:#f6c14a;text-shadow:0 3px 0 #7a3a12,0 8px 24px rgba(0,0,0,.5)}
#splash .tag{margin:0 0 18px;font:italic 17px/1.4 Georgia,"Times New Roman",serif;color:#c9a87f}
#splash .bar{width:min(300px,70vw);height:12px;padding:2px;border:2px solid #b4551d;border-radius:3px;background:#2a1608;box-sizing:content-box}
#splash .fill{height:100%;width:0;background:repeating-linear-gradient(90deg,#63e6e2 0 10px,#4cc9c5 10px 12px);transition:width .2s}
#splash.wait .fill{width:100%;opacity:.55;animation:pulse 1.2s ease-in-out infinite}
#splash .say{min-height:22px;font:20px/1.1 Jersey10,"Courier New",monospace;letter-spacing:.03em;color:#c9a87f}
#splash.stopped .bar{border-color:#d9534f}
#splash.stopped .say{color:#ff8a80}
@keyframes bob{50%{transform:translateY(-6px)}}
@keyframes pulse{50%{opacity:.25}}
@media (prefers-reduced-motion:reduce){#splash img,#splash.wait .fill{animation:none}}
@media (max-height:420px){#splash img{width:64px;height:64px}#splash h1{font-size:40px}#splash .tag{display:none}}
</style>"""

SPLASH = """<div id=splash class=wait role=status aria-live=polite>
<img src=loading/icon.png alt="">
<h1>PIXALORIEN</h1>
<p class=tag>Three go down, a treasure comes back up</p>
<div class=bar><div class=fill></div></div>
<div class=say>Loading the planet&hellip;</div>
</div>"""

# After the page's own script (which makes Module) and before index.js.
SCRIPT = """<script>!function(){
var splash=document.getElementById("splash"),fill=splash.querySelector(".fill"),say=splash.querySelector(".say"),stopped=false;
function tell(t){if(!stopped)say.textContent=t}
var setStatus=Module.setStatus;
Module.setStatus=function(t){setStatus&&setStatus(t);if(stopped)return;
 var m=/\\((\\d+)\\/(\\d+)\\)/.exec(t||"");
 if(m&&+m[2]>0){var p=Math.min(100,Math.floor(100*m[1]/m[2]));splash.classList.remove("wait");fill.style.width=p+"%";tell(p<100?"Loading the planet\\u2026 "+p+"%":"Landing\\u2026")}
 else if(/Running/.test(t||"")){splash.classList.add("wait");tell("Landing\\u2026")}};
var ready=Module.onRuntimeInitialized;
Module.onRuntimeInitialized=function(){ready&&ready.apply(this,arguments);
 requestAnimationFrame(function(){requestAnimationFrame(function(){setTimeout(function(){if(!stopped)document.body.classList.add("ready")},150)})})};
var onerror=window.onerror;
window.onerror=function(){var r=onerror&&onerror.apply(this,arguments);stopped=true;
 splash.classList.remove("wait");splash.classList.add("stopped");document.body.classList.remove("ready");
 say.textContent="The game stopped. Reload the page to try again.";return r};
}()</script>"""


def main(path):
    page = open(path, encoding="utf-8").read()

    def put(before, text, what):
        nonlocal page
        if page.count(before) != 1:
            sys.exit(f"web_page.py: {path} has no single {what} ({before!r}): not the page ent writes?")
        page = page.replace(before, text + before)

    if "id=splash" in page:
        sys.exit(f"web_page.py: {path} has its loading screen already")
    page = page.replace("<title>ent</title>", "<title>Pixalorien</title>")
    put("</head>", '<link rel=icon href=loading/icon.png>' + STYLE, "</head>")
    put("<main>", SPLASH, "<main>")
    put("<script async src=index.js>", SCRIPT, "index.js script")
    open(path, "w", encoding="utf-8").write(page)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
