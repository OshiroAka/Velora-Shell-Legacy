import json
import os
import shutil
import tempfile
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WallpaperAccordionTests(unittest.TestCase):
    def test_geometry_and_bounded_library_window(self):
        source = (ROOT / "core/WallpaperAccordionGeometry.js").read_text()
        script = source.replace(".pragma library", "") + '''
for (const [w,h] of [[1366,768],[1280,800],[1600,900],[1920,1080],[1920,1200],[2560,1440]]) {
  for (const scale of [1,1.25,1.5,2]) {
    for (const total of [0,1,2,100,500,5000]) {
      const aw = w / scale - 64, ah = h / scale - 40;
      const m = layout(aw,ah,total);
      if (m.stageX < 0 || m.stageX+m.stageWidth > aw+0.001) throw Error('stage');
      if (m.stageY < 0 || m.stageY + m.cardHeight > ah + 0.001 || m.visibleCount > 11) throw Error('bounds');
      for (const selected of [0,Math.max(0,total-1)]) {
        const start = windowStart(total,m.visibleCount,selected,0);
        const indices = windowIndices(total,m.visibleCount,start);
        if (indices.length > m.visibleCount+2 || new Set(indices).size !== indices.length) throw Error('window');
        for (const progress of [0,.2,.5,.8,1]) {
          const rects = rectangles(m,m.visibleCount,Math.max(0,m.visibleCount-1),0,progress);
          if (rects.some(r=>r.width < 0)) throw Error('width');
          if (rects.length && rects.at(-1).x+rects.at(-1).width > m.stageWidth+0.001) throw Error('overflow');
        }
      }
    }
  }
}
console.log(JSON.stringify({passed:true}));
'''
        result = subprocess.run(["node", "-e", script], capture_output=True, text=True, check=True)
        self.assertTrue(json.loads(result.stdout)["passed"])

    def test_preview_budget_and_reduced_motion_contract(self):
        qml = (ROOT / "components/VeloraWallpaperCarousel.qml").read_text()
        self.assertIn("model: cardModel", qml)
        self.assertIn("!reducedMotion", qml)
        self.assertNotIn("OpacityMask", qml)
        self.assertNotIn("Canvas", qml)
        self.assertIn("sourceSize.width: 720", qml)
        self.assertIn("onDoubleClicked", qml)
        self.assertNotIn("onEntered: carousel.applyRequested", qml)

    def test_conserved_spacing_and_interrupted_retarget(self):
        source = (ROOT / "core/WallpaperAccordionGeometry.js").read_text().replace(".pragma library", "")
        script = source + r"""
const assert = require('assert/strict');
for (const [w,h] of [[683,384],[1366,768],[1920,1080],[2560,1440]]) {
 const m = layout(w-64,h-40,500), step = m.collapsedWidth + m.gap;
 let weights = {0:1}, offset = 0;
 for (const selected of [1,3,2,4,5,6,3,9,499,0]) {
   const before = Array.from({length:500},(_,i)=>rect(m,i,weights,offset));
   const start = windowStart(500,m.visibleCount,selected,Math.round(offset/step));
   const from = compact(weights);
   for (const p of [0,.07,.25,.5,.8,1]) {
     const mixed=blend(from,selected,p), scroll=offset+(start*step-offset)*p;
     const indices=visibleIndices(m,500,mixed,scroll);
     assert(indices.length <= Math.ceil(m.stageWidth/step)+3, 'bounded intermediate window');
     assert(indices.filter(i=>{const r=rect(m,i,mixed,scroll);return r.x+r.width<0 || r.x>m.stageWidth}).length<=2, 'one buffer per edge');
     let sum = 0;
     for (let i=0;i<500;i++) {
       const r=rect(m,i,mixed,scroll); sum+=r.focus;
       if (p===0) { assert(Math.abs(r.x-before[i].x)<.01); assert(Math.abs(r.width-before[i].width)<.01); }
       if (i) { const prev=rect(m,i-1,mixed,scroll); assert(Math.abs(r.x-prev.x-prev.width-m.gap)<1e-6,'spacing/overlap'); }
     }
     assert(Math.abs(sum-1)<1e-6,'expansion budget');
   }
   // Interrupt well before rest. The next target must start at this exact pose.
   weights=blend(from,selected,.31); offset+=(start*step-offset)*.31;
 }
}
for (const [w,expected] of [[1366,7],[1920,9],[2560,11]]) assert.equal(layout(w-64,900,500).visibleCount,expected);
"""
        result = subprocess.run(["node", "-e", script], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_qml_motion_lifecycle_and_input(self):
        with tempfile.TemporaryDirectory(prefix="velora-motion-test-") as directory:
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=directory)
            env.pop("WAYLAND_DISPLAY", None)
            fixture = (ROOT / "tests/fixtures/tst_surface_motion.qml").read_text().replace('"../../', '"' + ROOT.as_uri() + '/')
            if shutil.which("ffmpeg"):
                movie = Path(directory) / "preview.mp4"
                subprocess.run(["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "testsrc2=size=64x64:rate=10",
                                "-t", "1", "-c:v", "mpeg4", str(movie)], check=True, capture_output=True)
                fixture = fixture.replace('property url previewPath: ""', 'property url previewPath: "' + movie.as_uri() + '"')
            test_file = Path(directory) / "tst_surface_motion.qml"
            test_file.write_text(fixture)
            result = subprocess.run(["/usr/lib/qt6/bin/qmltestrunner", "-input", str(test_file)],
                                    env=env, capture_output=True, text=True, timeout=35)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertNotIn("QWARN", output)
            self.assertNotIn("undefined", output)
