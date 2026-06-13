// UI.h — Volt's own immediate-mode UI framework.
//
// This is the "no other people's UI library" part: every widget below is
// implemented by hand in UI.cpp on top of the raw Direct2D primitives in
// Renderer. It is an immediate-mode design (like a from-scratch take on the
// IMGUI *pattern*, not the Dear ImGui *library*): you call ui.button(...)
// each frame and it returns whether it was clicked. State that must persist
// between frames (hover/press animation, slider drag, scroll offset, toggle
// knob position) is keyed by a stable widget id and stored in the Context.
#pragma once

#include <string>
#include <unordered_map>
#include "Renderer.h"
#include "Theme.h"

namespace volt {

// Raw input collected from the Win32 message loop, handed to the UI each frame.
struct Input {
    float mouseX = 0, mouseY = 0;
    bool  mouseDown = false;       // current left-button state
    bool  mousePressed = false;    // went down this frame
    bool  mouseReleased = false;   // came up this frame
    float wheel = 0;               // accumulated wheel delta this frame
    std::wstring typed;            // characters typed this frame
    bool  backspace = false;
    bool  enter = false;
    float dt = 1.0f / 60.0f;       // seconds since last frame
};

// Per-widget animation/interaction state persisted across frames.
struct WidgetState {
    float hover = 0;     // 0..1 hover blend
    float press = 0;     // 0..1 press blend
    float knob  = 0;     // toggle knob position / generic anim value
    float scroll = 0;    // scroll offset for scroll regions
    bool  active = false;// is being dragged (slider) / focused (textbox)
};

class UI {
public:
    UI(Renderer& r) : m_r(r) {}

    // Frame lifecycle.
    void begin(const Input& in);
    void end();

    // --- layout ----------------------------------------------------------
    // A simple vertical cursor inside a content column. Widgets advance it.
    void setColumn(const Rect& region, float gap = 8.0f);
    Rect row(float height);            // claim the next row of given height
    void spacer(float h);
    Rect content() const { return m_col; }

    // --- widgets (return value = interaction result this frame) ----------
    bool button(const std::wstring& id, const std::wstring& label,
                const Rect& r, bool primary = false);
    bool iconButton(const std::wstring& id, const std::wstring& glyph, const Rect& r,
                    const Color& tint, bool on = false);
    // Toggle switch. `value` is read+written in place. Returns true if changed.
    bool toggle(const std::wstring& id, const std::wstring& label, bool& value,
                const Rect& r);
    // Float slider. Returns true while being dragged.
    bool slider(const std::wstring& id, const std::wstring& label, float& value,
                float lo, float hi, const Rect& r, const wchar_t* fmt = L"%.0f");
    void label(const std::wstring& s, const Rect& r, const Color& c,
               Font f = Font::Body, TextAlign a = TextAlign::Left);
    void panel(const Rect& r, const Color& c, float radius = metric::Radius);
    void separator(const Rect& r);

    // Vertical nav-rail item (square icon + active indicator). Returns true on click.
    bool railItem(const std::wstring& id, const std::wstring& glyph,
                  const Rect& r, bool selected);

    // Begin a clipped, scrollable region. Returns the inner content rect
    // already offset by the scroll position. Call endScroll() after filling it.
    Rect beginScroll(const std::wstring& id, const Rect& view, float contentHeight);
    void endScroll();

    // Single-line text input. Edits `buffer` in place. Returns true on Enter.
    bool textInput(const std::wstring& id, std::wstring& buffer, const Rect& r,
                   const std::wstring& placeholder = L"");

    const Input& input() const { return m_in; }

private:
    WidgetState& state(const std::wstring& id);
    bool hot(const Rect& r) const;             // mouse over rect
    void animHoverPress(WidgetState& s, bool isHot, bool isDown);

    Renderer& m_r;
    Input m_in;
    std::unordered_map<std::wstring, WidgetState> m_state;

    // active scroll region bookkeeping
    std::wstring m_scrollId;
    Rect m_scrollView{};

    // column layout cursor
    Rect  m_col{};
    float m_cursorY = 0;
    float m_gap = 8.0f;
};

} // namespace volt
