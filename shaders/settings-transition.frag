#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 surfaceSize;
    vec4 accent;
    float progress;
    float effect;
} ubuf;
vec3 landscape(vec2 p, bool second) {
    vec3 sky = second ? mix(vec3(.29,.37,.44),ubuf.accent.rgb,.23) : vec3(.48,.40,.38);
    vec3 color = mix(sky*1.16,sky*.68,p.y);
    vec2 sun = (p-vec2(second ? .72 : .27,.30))*vec2(1.7,1.0);
    float circle = 1.0-smoothstep(.083,.09,length(sun));
    color = mix(color,second ? vec3(.82,.86,.87) : vec3(.96,.82,.65),circle);
    float hill = .64 + .09*sin(p.x*8.0+(second ? 1.2 : 0.0));
    color = mix(color,sky*.57,smoothstep(hill-.006,hill+.006,p.y));
    float near = .82 + .05*sin(p.x*10.0+(second ? 3.0 : 1.0));
    return mix(color,sky*.32,smoothstep(near-.006,near+.006,p.y));
}
void main() {
    vec2 p=qt_TexCoord0;
    float t=ubuf.progress;
    float reveal=t;
    if (ubuf.effect > .5 && ubuf.effect < 1.5) {
        float edge=t*1.22-.11+.08*sin(p.y*8.0+t*5.0)*sin(t*3.14159);
        reveal=1.0-smoothstep(edge-.025,edge+.025,p.x);
    } else if (ubuf.effect < 2.5 && ubuf.effect > 1.5) {
        reveal=1.0-smoothstep(t-.004,t+.004,p.x);
    } else if (ubuf.effect < 3.5 && ubuf.effect > 2.5) {
        reveal=1.0-smoothstep(t*1.03-.01,t*1.03+.01,length((p-.5)*vec2(1.7,1.0)));
    } else if (ubuf.effect > 3.5) {
        reveal=smoothstep((1.0-t)*1.03-.01,(1.0-t)*1.03+.01,length((p-.5)*vec2(1.7,1.0)));
    }
    if (t<=0.0) reveal=0.0;
    if (t>=1.0) reveal=1.0;
    vec2 q=abs(p*ubuf.surfaceSize-ubuf.surfaceSize*.5)-ubuf.surfaceSize*.5+12.0;
    float d=min(max(q.x,q.y),0.0)+length(max(q,0.0))-12.0;
    float coverage=1.0-smoothstep(-.75,.75,d);
    fragColor=vec4(mix(landscape(p,false),landscape(p,true),reveal)*coverage,coverage)*ubuf.qt_Opacity;
}
