import QtQuick
import QtQuick.Window
import Quickshell
import "../../core" as Core
import "../../components" as Components
import "../../features/editor" as Editor
ShellRoot {
 id: test
 QtObject { id: config; property bool reducedMotion: false; property string motionPreset: "balanced"
  property string barMaterial: "glass"; property string liquidGlassStyle: "frosted"
  property real barOpacity: .4; property real barWaveStrength: .5
  function setBarAppearance(material, wave) {barMaterial=material;barWaveStrength=wave} }
 QtObject { id: testPalette; property var config: null
  property color accentSoft: "#abb"; property color moduleSurface: "#222"; property color barSurface: "#334"
  property color textPrimary: "#eee"; property color textSecondary: "#bbb"
  property color accent: "#abb"; property color borderStrong: "#888"; property color borderSubtle: "#444"
  property string bodyFont: "Sans" }
 Core.Motion { id: testMotion; config: config }
 Window {
  width: 1120; height: 650; visible: true
  Components.VeloraSettingsSlider { id: slider; width: parent.width; theme: testPalette; label: "Fixture"; value: .4 }
  Components.VeloraSettingsTabs { id: tabs; y: 90; theme: testPalette; motion: testMotion; width: 560
   options: [{id:"fade",label:"Fade"},{id:"wave",label:"Wave"},{id:"wipe",label:"Wipe"},{id:"grow",label:"Grow"},{id:"outer",label:"Outer"},{id:"random",label:"Random"}]; selected: "fade" }
  Editor.SettingsMaterialChoices { id: materials; y: 650; width: 814; theme: testPalette; config: config; motion: testMotion }
  Editor.SettingsMotionPreview { id: structuralPreview; y: 430; width: 520; theme: testPalette; motion: testMotion }
  Loader { id: previewLoader; y: 150; width: 350; active: true
   sourceComponent: Editor.WallpaperTransitionPreview { theme: testPalette; motion: testMotion; duration: .15; height: implicitHeight } }
 }
 function find(item,label) { if(item.label===label)return item; for(const child of item.children||[]) {const result=find(child,label);if(result)return result}return null }
 function assert(value,message) { if (!value) throw new Error(message) }
 property int step: 0
 Timer { interval: 350; running: true; repeat: true
  onTriggered: {
   try {
    const preview=previewLoader.item
    if(step===0) {
     assert(slider.trackWidth<=232,"desktop slider is too wide")
     const liquid=find(materials,"Liquid glass")
     assert(liquid.y===0,"material cards unexpectedly wrap on a wide page")
     liquid.triggered(); assert(config.barMaterial==="liquid","material choice calls existing setter")
     materials.width=480
     slider.width=320
     assert(slider.trackWidth<=232 && slider.implicitHeight>=68,"compact slider is clipped")
     tabs.width=270
     assert(tabs.columns===3 && tabs.implicitHeight===72,"tabs do not wrap")
     for(const mode of ["fade","wave","wipe","grow","outer","random"]) {
      preview.mode=mode; preview.replay(); assert(preview.animating,"preview did not start: "+mode)
     }
    } else if(step===1) {
     assert(!preview.animating && preview.progress===1,"preview keeps working at rest")
     assert(materials.columns===2 && find(materials,"Liquid glass").y>0,"material cards wrap at compact widths")
     assert(!structuralPreview.animating && structuralPreview.expansion===1 && structuralPreview.contents===1,"motion preview settles")
     structuralPreview.replay(); assert(structuralPreview.animating,"motion replay starts")
     structuralPreview.visible=false; assert(!structuralPreview.animating,"hidden motion preview stops")
     preview.replay(); preview.visible=false
     assert(!preview.animating,"hidden preview keeps animating")
     config.reducedMotion=true; preview.visible=true; preview.replay()
     structuralPreview.visible=true; structuralPreview.replay()
     assert(!structuralPreview.animating && structuralPreview.contents===1,"reduced motion preview remains static")
     assert(!preview.animating && preview.progress===.5,"reduced motion preview moves")
     previewLoader.active=false
    } else if(step===2) {
     assert(previewLoader.item===null,"closed preview retained rendering objects")
     console.info("SETTINGS_CONTROLS_OK");Qt.quit()
    }
    step++
   } catch(error) {console.error("SETTINGS_CONTROLS_FAILED",String(error));Qt.quit()}
  }
 }
}
