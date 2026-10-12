import json
import os
from pathlib import Path
import shutil
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SurfaceGeometryTests(unittest.TestCase):
    def test_shell_panels_respect_fractional_logical_boundaries(self):
        source = (ROOT / "ShellController.qml").read_text()
        names = ["barX", "mainAreaX", "mainAreaRightInset", "mainAreaWidth", "quickPopupX",
                 "preferredQuickPopupX", "quickPopupUsesReferencePlacement", "quickPopupWidth",
                 "quickPopupWidthForScreen", "quickPopupHeight", "quickPopupHeightForScreen",
                 "quickPopupTopMargin", "quickPopupY", "topWallpaperPopupWidth", "topWallpaperPopupHeight"]
        functions = []
        for name in names:
            match = re.search(r"    function " + name + r"\([^)]*\)\s*\{", source)
            self.assertIsNotNone(match, name)
            depth, end = 1, match.end()
            while depth:
                depth += (source[end] == "{") - (source[end] == "}")
                end += 1
            functions.append(source[match.start():end])
        geometry = (ROOT / "core/SurfaceGeometry.js").read_text().replace(".pragma library", "")
        script = "const assert=require('assert/strict');const SurfaceGeometry=(()=>{" + geometry + ";return {clamp};})();\n"
        script += "let barOnRight=false,sideBarLayoutEnabled=true,topBarLayout=false,frameVisualInset=8,barPanelWidth=64,sidebarVisualWidth=64,sidebarOuterMargin=0,popupFrameGap=8,sideQuickPopupBarClearance=12,barReserveWidth=64,desktopFrameMargin=8,notificationHistoryCount=7,quickPopupCenterY=0;\n"
        script += "\n".join(functions)
        script += r'''
for (const [pw,ph] of [[1280,800],[1366,768],[1600,900],[1920,1080],[1920,1200],[2560,1440]])
 for (const scale of [1,1.25,1.5,2]) for (const right of [false,true]) {
  const w=pw/scale,h=ph/scale-40;barOnRight=right;quickPopupCenterY=h*.8;
  for (const type of ["theme","settings","agenda","weatherPanel","time","search","files","browser","volume","wifi","brightness","quickSettings","settingsQuick","notifications","battery","bluetooth","wallpaperVisibility","workspaces","apps","media","profile"]) {
   const width=quickPopupWidthForScreen(type,w),height=quickPopupHeightForScreen(type,h);
   const x=quickPopupX(type,w,width),y=quickPopupY(type,height,h);
   assert(x>=mainAreaX(w)-1e-6 && x+width<=w-mainAreaRightInset(w)+1e-6,`${type} horizontal ${w}@${scale}`);
   assert(y>=0 && y+height<=h+1e-6,`${type} vertical ${h}@${scale}`);
  }
  assert(topWallpaperPopupWidth(w)<=w-barReserveWidth-desktopFrameMargin*4+1e-6);
  assert(topWallpaperPopupHeight(h)<=h-64+1e-6);
 }
assert.equal(topWallpaperPopupWidth(1920),1340);
assert.equal(topWallpaperPopupHeight(1200),840);
'''
        result = subprocess.run(["node", "-e", script], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_resolution_scale_sides_and_rotated_desktop_geometry(self):
        libraries = {"surface": "core/SurfaceGeometry.js", "bar": "features/topbar/BarGeometry.js",
                     "timer": "features/topbar/TimerGeometry.js", "popover": "features/topbar/TopBarGeometry.js"}
        script = "const assert = require('assert/strict');\n"
        for name, path in libraries.items():
            source = (ROOT / path).read_text().replace(".pragma library", "")
            exports = {"surface": "area,fit,designBounds,pose", "bar": "sections", "timer": "panel", "popover": "panel"}[name]
            script += f"const {name} = (()=>{{{source};return {{{exports}}};}})();\n"
        script += r'''
let count = 0;
const matrix = [[1280,800],[1366,768],[1600,900],[1920,1080],[1920,1200],[2560,1440]];
// Each table entry is also tested as a physical output at four compositor
// scales. The resulting logical size is passed once into the surface helpers.
for (const [physicalW, physicalH] of matrix) for (const scale of [1,1.25,1.5,2]) {
 const w = physicalW / scale, h = physicalH / scale;
 for (const right of [false,true]) {
  const bounds = surface.area(w,h,64,right,40,18,8);
  for (const [pw,ph] of [[1510,1040],[920,650],[540,990],[1020,760],[560,620]]) {
   for (const x of [-100,0,w/2,w+500]) for (const y of [-100,0,h/2,h+500]) {
    const rect = surface.fit(bounds,pw,ph,x,y);
    assert(rect.x >= bounds.x && rect.x+rect.width <= bounds.x+bounds.width+1e-6);
    assert(rect.y >= bounds.y && rect.y+rect.height <= bounds.y+bounds.height+1e-6);
    count++;
   }
  }
  const left = right ? 8 : 72, edge = right ? 72 : 8;
  for (const progress of [0,.1,.5,.9,1]) for (const anchor of [0,64,w/2,w-64,w]) {
   for (const rect of [timer.panel(w,h,40,anchor,74,416,368,progress,left,edge),
                      popover.panel(w,h,40,anchor,416,368,progress,left,edge)]) {
    assert(rect.x >= left && rect.x+rect.width <= w-edge+1e-6);
    assert(rect.y >= 40 && rect.y+rect.height <= h-16+1e-6);
    count++;
   }
  }
  const design = surface.designBounds(w,h,64,right,40,18);
  for (const rotation of [-180,-70,0,25,90,160]) for (const x of [-300,100,800,1800]) {
   const rect = surface.pose({x:x,y:800,scale:2,rotation:rotation,opacity:.8},302,294,design);
   const rad=rotation*Math.PI/180, c=Math.cos(rad), s=Math.sin(rad);
   for (const [dx,dy] of [[0,0],[302,0],[0,294],[302,294]]) {
    const px=rect.x+(dx*c-dy*s)*rect.scale, py=rect.y+(dx*s+dy*c)*rect.scale;
    assert(px>=design.x-1e-6 && px<=design.x+design.width+1e-6);
    assert(py>=design.y-1e-6 && py<=design.y+design.height+1e-6);
   }
   assert.equal(rect.opacity,.8);
   count++;
  }
 }
 for (const wanted of [[548,330,620],[0,330,750],[250,0,780],[0,0,750]]) {
  const rects=bar.sections(w,...wanted,0,20);
  assert(rects.left.x+rects.left.width <= rects.center.x+1e-6);
  assert(rects.center.x+rects.center.width <= rects.right.x+1e-6);
  assert(rects.right.x+rects.right.width <= w+1e-6);
  count++;
 }
}
const reference=bar.sections(1920,548,330,620,0,20);
assert.equal(reference.left.x,0); assert.equal(reference.left.width,548);
assert.equal(reference.center.x,795); assert.equal(reference.right.x,1280);
const original={x:120,y:120,scale:1,rotation:0,opacity:1};
assert.deepEqual(surface.pose(original,302,294,surface.designBounds(1920,1200,64,false,40,18)),original);
console.log(JSON.stringify({cases:count,outputs:matrix.length,scales:4,sides:2}));
'''
        result = subprocess.run(["node", "-e", script], capture_output=True, text=True, check=True)
        self.assertGreater(json.loads(result.stdout)["cases"], 7000)

    def test_actual_qml_popovers_resize_without_cutting_content(self):
        runner = shutil.which("qs")
        if not runner: self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-geometry-test-") as directory:
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=directory, VELORA_VALIDATE="1")
            env.update(XDG_CONFIG_HOME=directory + "/config-home", XDG_CACHE_HOME=directory + "/cache", XDG_DATA_HOME=directory + "/data", XDG_STATE_HOME=directory + "/state")
            env.pop("WAYLAND_DISPLAY", None)
            env.pop("QT_SCREEN_SCALE_FACTORS", None)
            for name in ("components", "core", "features", "platform", "services", "assets", "config", "scripts"):
                (Path(directory) / name).symlink_to(ROOT / name, target_is_directory=True)
            fixture = (ROOT / "tests/fixtures/tst_surface_geometry.qml").read_text().replace('"../../', '"./')
            path = Path(directory) / "shell.qml"
            path.write_text(fixture)
            for scale in (1, 1.25, 1.5, 2):
                with self.subTest(qt_scale=scale):
                    env["QT_SCALE_FACTOR"] = str(scale)
                    result = subprocess.run([runner, "-p", str(path)], env=env, text=True, capture_output=True, timeout=30)
                    output = result.stdout + result.stderr
                    self.assertEqual(result.returncode, 0, output)
                    match = re.search(r'GEOMETRY_RESULT (\{[^\n]+\})', output)
                    self.assertIsNotNone(match, output)
                    state = json.loads(match[1])
                    self.assertTrue(state["passed"], output)
                    self.assertEqual(state["cases"], 60)
                    self.assertAlmostEqual(state["devicePixelRatio"], scale, places=5)
