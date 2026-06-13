// Renderer.h — thin Direct2D / DirectWrite drawing surface.
//
// Direct2D + DirectWrite are Windows OS graphics APIs (the same layer a
// browser or game launcher draws with). They are NOT a UI toolkit: they
// give us "fill a rounded rectangle", "draw this glyph run", nothing more.
// Every button, slider, tab and animation is built on top of these
// primitives by our own UI layer in UI.h — no external widget library.
#pragma once

#include <windows.h>
#include <d2d1.h>
#include <dwrite.h>
#include <string>
#include "Theme.h"

namespace volt {

struct Rect {
    float x, y, w, h;
    float right()  const { return x + w; }
    float bottom() const { return y + h; }
    float cx()     const { return x + w * 0.5f; }
    float cy()     const { return y + h * 0.5f; }
    bool contains(float px, float py) const {
        return px >= x && px <= x + w && py >= y && py <= y + h;
    }
    Rect inset(float d) const { return { x + d, y + d, w - 2 * d, h - 2 * d }; }
};

enum class TextAlign { Left, Center, Right };

// Named font slots so widgets ask for "Body" / "Title" instead of sizes.
enum class Font { Body, Small, Title, Mono, Icon };

class Renderer {
public:
    bool init(HWND hwnd);
    void shutdown();
    void resize(UINT w, UINT h);

    // Frame lifecycle. Returns false if the device was lost (caller skips frame).
    bool beginFrame(const Color& clear);
    void endFrame();

    // --- primitives ------------------------------------------------------
    void fillRect(const Rect& r, const Color& c);
    void fillRoundRect(const Rect& r, float radius, const Color& c);
    void strokeRoundRect(const Rect& r, float radius, const Color& c, float thickness = 1.0f);
    void line(float x0, float y0, float x1, float y1, const Color& c, float thickness = 1.0f);
    void circle(float cx, float cy, float radius, const Color& c);

    // Vertical two-stop gradient fill of a rounded rect (used for accents / glow).
    void gradientRoundRect(const Rect& r, float radius, const Color& top, const Color& bottom);

    // Soft drop shadow approximated by stacked translucent rounded rects.
    void dropShadow(const Rect& r, float radius, const Color& c, float spread = 10.0f);

    void text(const std::wstring& s, const Rect& box, const Color& c,
              Font font = Font::Body, TextAlign align = TextAlign::Left,
              bool vcenter = true);

    // Measure a string's pixel width for a given font (for layout decisions).
    float measure(const std::wstring& s, Font font);

    // Clip subsequent draws to `r` until popClip(). Used by scroll regions.
    void pushClip(const Rect& r);
    void popClip();

    UINT width()  const { return m_w; }
    UINT height() const { return m_h; }

private:
    ID2D1SolidColorBrush* brush(const Color& c);
    IDWriteTextFormat*    format(Font f);

    HWND                     m_hwnd  = nullptr;
    ID2D1Factory*            m_d2d   = nullptr;
    ID2D1HwndRenderTarget*   m_rt    = nullptr;
    ID2D1SolidColorBrush*    m_brush = nullptr;   // reused, recolored per call
    IDWriteFactory*          m_dw    = nullptr;
    IDWriteTextFormat*       m_fBody  = nullptr;
    IDWriteTextFormat*       m_fSmall = nullptr;
    IDWriteTextFormat*       m_fTitle = nullptr;
    IDWriteTextFormat*       m_fMono  = nullptr;
    IDWriteTextFormat*       m_fIcon  = nullptr;
    UINT m_w = 0, m_h = 0;
};

} // namespace volt
