#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <array>
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <string>

constexpr int WIDTH = 400, HEIGHT = 300;

GLuint compile(GLenum type, const std::string& source) {
    GLuint shader = glCreateShader(type);
    const char* text = source.c_str();
    glShaderSource(shader, 1, &text, nullptr);
    glCompileShader(shader);
    GLint success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        char message[4096];
        glGetShaderInfoLog(shader, sizeof(message), nullptr, message);
        throw std::runtime_error(message);
    }
    return shader;
}

int main(int argc, char** argv) {
    try {
        if (argc != 3) return 2;
        EGLDisplay display = eglGetPlatformDisplay(EGL_PLATFORM_SURFACELESS_MESA, EGL_DEFAULT_DISPLAY, nullptr);
        if (!eglInitialize(display, nullptr, nullptr)) return 77;
        eglBindAPI(EGL_OPENGL_ES_API);
        const EGLint attributes[] = {EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
            EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_NONE};
        EGLConfig config;
        EGLint count;
        if (!eglChooseConfig(display, attributes, &config, 1, &count) || !count) return 77;
        const EGLint contextAttributes[] = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE};
        EGLContext context = eglCreateContext(display, config, EGL_NO_CONTEXT, contextAttributes);
        const EGLint surfaceAttributes[] = {EGL_WIDTH, WIDTH, EGL_HEIGHT, HEIGHT, EGL_NONE};
        EGLSurface surface = eglCreatePbufferSurface(display, config, surfaceAttributes);
        if (!eglMakeCurrent(display, surface, surface, context)) return 77;

        GLuint program = glCreateProgram();
        for (int index = 1; index <= 2; ++index) {
            std::ifstream file(argv[index]);
            std::string source{std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>()};
            glAttachShader(program, compile(index == 1 ? GL_VERTEX_SHADER : GL_FRAGMENT_SHADER, source));
        }
        glLinkProgram(program);
        GLint linked;
        glGetProgramiv(program, GL_LINK_STATUS, &linked);
        if (!linked) throw std::runtime_error("Bar shader did not link");
        glUseProgram(program);

        GLuint vao, buffer, texture;
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);
        glGenBuffers(1, &buffer);
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
        const float vertices[] = {-1,1,0,0, -1,-1,0,1, 1,1,1,0, 1,-1,1,1};
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
        for (auto [name, offset] : {std::pair{"pos", 0}, std::pair{"texcoord", 2}}) {
            GLint location = glGetAttribLocation(program, name);
            glEnableVertexAttribArray(location);
            glVertexAttribPointer(location, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), reinterpret_cast<void*>(offset * sizeof(float)));
        }
        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_2D, texture);
        const unsigned char background[] = {96, 128, 160, 255};
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, background);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        auto one = [&](const char* name, float value) { glUniform1f(glGetUniformLocation(program,name),value); };
        auto two = [&](const char* name, float x, float y) { glUniform2f(glGetUniformLocation(program,name),x,y); };
        auto four = [&](const char* name, float x, float y, float z, float w) { glUniform4f(glGetUniformLocation(program,name),x,y,z,w); };
        const float identity[] = {1,0,0, 0,1,0, 0,0,1};
        glUniformMatrix3fv(glGetUniformLocation(program,"proj"),1,GL_FALSE,identity);
        two("fullSize",WIDTH,HEIGHT);
        two("windowTopLeft",0,0);
        two("windowBottomRight",1,1);
        four("frameInterior",40,30,420,252);
        one("frameRadius",20);
        four("barTint",0.1,0.12,0.15,0.3);
        one("radius",18);
        one("radiusOuter",8);
        one("alpha",1);
        std::array<float,96> bands;
        bands.fill(0.6);
        glUniform1fv(glGetUniformLocation(program,"barBands"),96,bands.data());
        auto draw = [&] { glClearColor(0,0,0,0); glClear(GL_COLOR_BUFFER_BIT); glDrawArrays(GL_TRIANGLE_STRIP,0,4); };
        auto alpha = [&](int x, int y) {
            unsigned char pixel[4];
            glReadPixels(x,HEIGHT-y-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel);
            return pixel[3];
        };
        auto check = [&](bool value, const char* message) { if (!value) throw std::runtime_error(message); };

        four("barMaterial",1,1,1,0);
        one("thick",3);
        two("topLeft",0,-135);
        two("bottomRight",200,15);
        two("uvOffset",0,-75);
        two("uvSize",55,35);
        four("pointer_shape",0,30,0,1);
        draw();
        check(alpha(200,75)>250,"Attached notification lost its material");
        check(alpha(200,32)>250,"Notification connection lost its material");
        check(alpha(200,140)==0,"Top panel paints outside its shape");
        check(alpha(200,220)==0,"Wave was drawn above application windows");
        four("statusPanel",110,-70,45,26);
        four("statusMetrics",110,25,18,8);
        draw();
        check(alpha(200,75)>250,"Open menu lost its material when notified");
        check(alpha(310,80)>250,"Notification lost its material beside an open menu");
        four("statusPanel",0,0,0,0);

        one("thick",4);
        two("topLeft",-200,0);
        two("bottomRight",40,180);
        two("uvOffset",-142,-10);
        two("uvSize",30,65);
        four("sideLabel",-100,-10,20,35);
        four("pointer_shape",1,0,132,1);
        one("radiusOuter",12);
        draw();
        check(alpha(60,140)>250,"Volume slider lost its enclosing material");
        check(alpha(100,140)>250,"Volume label lost its enclosing material");
        check(alpha(160,140)==0,"Sidebar paints outside its shape");
        check(alpha(200,220)==0,"Sidebar puts the wave above windows");
        check(alpha(200,290)==0,"Upper sidebar duplicates the desktop bottom frame");

        four("barMaterial",2,1,1,WIDTH);
        draw();
        check(alpha(20,140)==0,"Desktop wave duplicates the sidebar tint");
        check(alpha(60,140)==0,"Desktop wave duplicates the attached controls");
        check(alpha(200,290)>250,"Desktop wave does not own the bottom frame");
        check(alpha(200,130)==0,"Desktop wave exceeds its amplitude");
        // Check the unobstructed span, including the former frame/wave join.
        for (int x=65;x<WIDTH-12;++x) {
            check(alpha(x,220)>250,"Continuous wave contains a column gap");
            check(alpha(x,280)>250,"Continuous wave leaves a gap at its base");
            // Scan across the former cut, not just two pixels above it. The
            // material and its coverage must stay identical through the base.
            std::array<unsigned char,4> previous{};
            for (int y=278;y<HEIGHT;++y) {
                std::array<unsigned char,4> pixel{};
                glReadPixels(x,HEIGHT-y-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel.data());
                check(pixel[3]>250,"Frame/wave join contains a transparent seam");
                if (y>278) check(pixel==previous,"Frame/wave join changes tint or coverage");
                previous=pixel;
            }
        }
        // Turning the analyzer off must leave the same bottom frame mounted.
        four("barMaterial",2,1,1,0);
        draw();
        check(alpha(200,290)>250,"Disabling the spectrum removes the bottom frame");
        check(alpha(200,220)==0,"Disabled spectrum still draws a wave");
        check(alpha(20,140)==0,"Disabled spectrum duplicates the upper sidebar");
        // A bass-heavy input previously raised only the left side. Each half
        // must now receive the same beat response, without raising silence.
        bands.fill(0.05);
        for (int index=0;index<32;++index) bands[index]=0.6;
        glUniform1fv(glGetUniformLocation(program,"barBands"),96,bands.data());
        four("barMaterial",2,1,1,WIDTH);
        draw();
        check(alpha(80,220)>250,"Bass no longer raises the left side");
        check(alpha(320,220)>250,"Bass does not raise the right side equally");
        for (int x=65;x<WIDTH/2;++x)
            for (int y=175;y<282;++y)
                check(std::abs(int(alpha(x,y))-int(alpha(WIDTH-x-1,y)))<=1,
                    "Left/right beat response is unbalanced");
        bands.fill(0);
        glUniform1fv(glGetUniformLocation(program,"barBands"),96,bands.data());
        draw();
        check(alpha(80,220)==0 && alpha(320,220)==0,"Balanced wave moves in silence");
        // Settings and the bottom frame share one SDF and material. Sample
        // actual shader output across the old seam, with spectrum disabled.
        four("barMaterial",2,1,1,0);
        four("bottomPanel",200,225,110,95);
        two("bottomMetrics",18,32);
        draw();
        check(alpha(200,145)>250,"Connected Settings body is missing");
        check(alpha(88,278)>250,"Settings lost the concave bottom connection");
        check(alpha(75,200)==0,"Settings material escapes its side boundary");
        check(alpha(20,275)==0,"Connected Settings cover the sidebar avatar");
        std::array<unsigned char,4> seamReference{};
        glReadPixels(200,HEIGHT-260-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,seamReference.data());
        for (int y=261;y<HEIGHT;++y) {
            std::array<unsigned char,4> pixel{};
            glReadPixels(200,HEIGHT-y-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel.data());
            check(pixel==seamReference,"Settings/base join changes tint or coverage");
        }
        four("barMaterial",1,1,1,0);
        draw();
        check(alpha(200,290)==0 && alpha(200,200)==0,"Upper host duplicates connected Settings");
        four("barMaterial",2,1,1,0);
        four("bottomPanel",0,0,0,0);
        draw();
        check(alpha(200,200)==0 && alpha(200,290)>250,"Closing Settings does not restore the bare frame");
        // Tall right panels are partitioned between upper/bottom material
        // passes, with exactly one opaque owner on every row.
        four("frameInterior",40,30,356,252);
        four("oppositePanel",336,165,60,135);
        one("oppositeContour",1);
        const std::array<float,21> curve{0,.058,.089,.066,.016,0,.05,.074,.042,.005,.008,.079,.071,.008,0,.055,.074,.024,.005,.029,.063};
        glUniform1fv(glGetUniformLocation(program,"oppositeCurve"),21,curve.data());
        std::array<int,HEIGHT> upper{};
        four("barMaterial",1,1,1,0);
        one("thick",4);
        draw();
        for(int y=30;y<HEIGHT;++y) upper[y]=alpha(345,y);
        check(alpha(280,95)>alpha(280,57),"Right panel lost the reference waves");
        four("barMaterial",2,1,1,0);
        draw();
        for(int y=30;y<HEIGHT;++y)
            check(upper[y]+alpha(345,y)==255,"Right panel has a gap or double material at the bottom join");
        // The left rail consumes the same contour, with one material owner.
        two("uvSize",0,0);
        four("sideLabel",0,0,0,0);
        std::array<float,21> strongCurve;
        strongCurve.fill(.25F);
        glUniform1fv(glGetUniformLocation(program,"oppositeCurve"),21,strongCurve.data());
        glUniform1fv(glGetUniformLocation(program,"sideCurve"),21,strongCurve.data());
        one("sideWaveScale",.55F);
        one("sideWaveWidth",66);
        one("waveDockProgress",1);
        four("barMaterial",1,1,1,0);
        draw();
        check(alpha(50,150)>250 && alpha(65,150)==0,"Left wave missing or exceeds shared contour");
        for(int y=30;y<HEIGHT;++y) upper[y]=alpha(50,y);
        four("barMaterial",2,1,1,0);
        draw();
        for(int y=30;y<HEIGHT;++y)
            check(upper[y]+alpha(50,y)==255,"Left wave has a gap or double material at the bottom join");
        one("sideWaveScale",0);
        one("waveDockProgress",0);
        four("barMaterial",1,1,1,0);
        draw();
        check(alpha(50,150)==0,"Left wave remains after closing Spotify");
        // The lower wave retracts toward the left while the rail rises.
        bands.fill(.6);
        glUniform1fv(glGetUniformLocation(program,"barBands"),96,bands.data());
        four("barMaterial",2,1,1,WIDTH);
        draw();
        check(alpha(200,220)>250,"Bottom wave did not return after undocking");
        one("waveDockProgress",.5F);
        draw();
        check(alpha(200,220)==0 && alpha(80,260)>250,"Bottom wave does not retract progressively");
        one("waveDockProgress",1);
        draw();
        check(alpha(80,260)==0 && alpha(200,290)>250,"Docking hides the base or leaves lower peaks");
        one("waveDockProgress",0);
        four("oppositePanel",376,150,20,82);
        one("oppositeContour",0);
        const std::array<float,21> flat{};
        glUniform1fv(glGetUniformLocation(program,"oppositeCurve"),21,flat.data());
        four("oppositeLabel",326,98,30,22);
        four("barMaterial",1,1,1,0);
        draw();
        check(alpha(320,98)>250 && alpha(320,155)==0,"Lyrics extension escapes its row");
        four("oppositeLabel",0,0,0,0);
        four("oppositePanel",0,0,0,0);
        draw();
        check(alpha(320,98)==0,"Closing right panel leaves material behind");
        check(glGetError()==GL_NO_ERROR,"OpenGL error while drawing the bar");
        std::cout << "Notification, volume, frame and desktop wave rendered correctly\n";
        eglMakeCurrent(display,EGL_NO_SURFACE,EGL_NO_SURFACE,EGL_NO_CONTEXT);
        eglDestroySurface(display,surface);
        eglDestroyContext(display,context);
        eglTerminate(display);
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
