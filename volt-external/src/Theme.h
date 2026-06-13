// Theme.h — Volt purple palette + metrics.
// Pure data. No dependency on the renderer so the UI layer and the
// app layer can both pull colors without dragging Direct2D in.
#pragma once
#include <cstdint>

namespace volt {

// Packed 0xAARRGGBB color. We keep our own color type instead of leaning
// on a framework's so the whole UI stack stays self-contained.
struct Color {
    float r, g, b, a;

    constexpr Color() : r(0), g(0), b(0), a(1) {}
    constexpr Color(float r_, float g_, float b_, float a_ = 1.0f)
        : r(r_), g(g_), b(b_), a(a_) {}

    static constexpr Color rgb(int r, int g, int b, float a = 1.0f) {
        return Color(r / 255.0f, g / 255.0f, b / 255.0f, a);
    }

    Color withAlpha(float na) const { return Color(r, g, b, na); }

    // Linear interpolation toward `o` by t in [0,1]. Used everywhere for
    // hover/press/animation blending.
    Color lerp(const Color& o, float t) const {
        return Color(r + (o.r - r) * t,
                     g + (o.g - g) * t,
                     b + (o.b - b) * t,
                     a + (o.a - a) * t);
    }
};

// The Volt look — matches the purple chrome of the Lua build.
struct Theme {
    Color bg          = Color::rgb(15, 9, 24);       // window backdrop
    Color panel       = Color::rgb(19, 12, 32);      // raised panels
    Color panelAlt    = Color::rgb(25, 16, 42);      // list rows / inputs
    Color panelHover  = Color::rgb(33, 21, 56);      // hovered surface
    Color rail        = Color::rgb(13, 8, 22);       // left nav rail
    Color stroke      = Color::rgb(48, 30, 78);      // hairline borders

    Color accent      = Color::rgb(140, 70, 240);    // primary purple
    Color accent2     = Color::rgb(184, 116, 255);   // bright highlight
    Color accentDim   = Color::rgb(86, 44, 150);     // pressed / muted

    Color text        = Color::rgb(236, 228, 250);   // primary text
    Color textDim     = Color::rgb(150, 134, 178);   // secondary text
    Color textFaint   = Color::rgb(96, 84, 122);     // hints / disabled

    Color good        = Color::rgb(96, 224, 150);    // connected / OK
    Color warn        = Color::rgb(255, 196, 92);    // warnings
    Color bad         = Color::rgb(255, 96, 110);    // blocked / errors

    Color shadow      = Color::rgb(0, 0, 0, 0.55f);  // drop shadow
};

// Layout constants. One source of truth for the whole app.
namespace metric {
    constexpr float WindowW   = 720.0f;
    constexpr float WindowH   = 470.0f;
    constexpr float TitleBarH = 40.0f;
    constexpr float RailW     = 64.0f;
    constexpr float Radius    = 10.0f;     // default corner radius
    constexpr float RowH      = 30.0f;
    constexpr float Pad       = 14.0f;
}

inline const Theme& theme() {
    static Theme t;
    return t;
}

} // namespace volt
