// UI.cpp — implementation of Volt's hand-built widget set.
#include "UI.h"
#include <algorithm>
#include <cstdio>
#include <cmath>

namespace volt {

static float clampf(float v, float lo, float hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}
// Frame-rate independent exponential approach of `cur` toward `target`.
static float approach(float cur, float target, float rate, float dt) {
    float t = 1.0f - std::exp(-rate * dt);
    return cur + (target - cur) * t;
}

void UI::begin(const Input& in) {
    m_in = in;
}

void UI::end() {
    // nothing global to flush; state map persists between frames
}

WidgetState& UI::state(const std::wstring& id) {
    return m_state[id];   // default-constructs on first use
}

bool UI::hot(const Rect& r) const {
    return r.contains(m_in.mouseX, m_in.mouseY);
}

void UI::animHoverPress(WidgetState& s, bool isHot, bool isDown) {
    s.hover = approach(s.hover, isHot ? 1.0f : 0.0f, 16.0f, m_in.dt);
    s.press = approach(s.press, (isHot && isDown) ? 1.0f : 0.0f, 26.0f, m_in.dt);
}

// ---- layout ------------------------------------------------------------

void UI::setColumn(const Rect& region, float gap) {
    m_col = region;
    m_cursorY = region.y;
    m_gap = gap;
}

Rect UI::row(float height) {
    Rect r = { m_col.x, m_cursorY, m_col.w, height };
    m_cursorY += height + m_gap;
    return r;
}

void UI::spacer(float h) { m_cursorY += h; }

// ---- primitives-as-widgets ---------------------------------------------

void UI::panel(const Rect& r, const Color& c, float radius) {
    m_r.fillRoundRect(r, radius, c);
}

void UI::label(const std::wstring& s, const Rect& r, const Color& c, Font f, TextAlign a) {
    m_r.text(s, r, c, f, a);
}

void UI::separator(const Rect& r) {
    const Theme& t = theme();
    m_r.line(r.x, r.cy(), r.right(), r.cy(), t.stroke, 1.0f);
}

// ---- button ------------------------------------------------------------

bool UI::button(const std::wstring& id, const std::wstring& label,
                const Rect& r, bool primary) {
    const Theme& t = theme();
    WidgetState& s = state(id);
    bool isHot = hot(r);
    animHoverPress(s, isHot, m_in.mouseDown);

    Color base = primary ? t.accent : t.panelAlt;
    Color hov  = primary ? t.accent2 : t.panelHover;
    Color fill = base.lerp(hov, s.hover);
    fill = fill.lerp(primary ? t.accentDim : t.stroke, s.press * 0.6f);

    if (primary && s.hover > 0.01f) {
        // subtle glow halo on the primary action
        Rect glow = r.inset(-3.0f);
        m_r.fillRoundRect(glow, metric::Radius + 3, t.accent.withAlpha(0.18f * s.hover));
    }
    m_r.fillRoundRect(r, metric::Radius, fill);
    if (!primary)
        m_r.strokeRoundRect(r, metric::Radius, t.stroke.withAlpha(0.6f + 0.4f * s.hover), 1.0f);

    Color tc = primary ? Color::rgb(255, 255, 255) : t.text;
    m_r.text(label, r, tc, Font::Body, TextAlign::Center);

    return isHot && m_in.mouseReleased;
}

bool UI::iconButton(const std::wstring& id, const std::wstring& glyph, const Rect& r,
                    const Color& tint, bool on) {
    const Theme& t = theme();
    WidgetState& s = state(id);
    bool isHot = hot(r);
    animHoverPress(s, isHot, m_in.mouseDown);

    Color fill = (on ? tint.withAlpha(0.22f) : t.panelAlt)
                     .lerp(tint.withAlpha(0.32f), s.hover);
    m_r.fillRoundRect(r, 8.0f, fill);
    if (on) m_r.strokeRoundRect(r, 8.0f, tint.withAlpha(0.8f), 1.0f);
    m_r.text(glyph, r, on ? tint : t.textDim.lerp(tint, s.hover), Font::Icon,
             TextAlign::Center);
    return isHot && m_in.mouseReleased;
}

// ---- toggle switch -----------------------------------------------------

bool UI::toggle(const std::wstring& id, const std::wstring& label, bool& value,
                const Rect& r) {
    const Theme& t = theme();
    WidgetState& s = state(id);
    bool isHot = hot(r);
    animHoverPress(s, isHot, m_in.mouseDown);

    bool changed = false;
    if (isHot && m_in.mouseReleased) { value = !value; changed = true; }

    // label on the left
    Rect lbl = { r.x + 2, r.y, r.w - 56, r.h };
    m_r.text(label, lbl, value ? t.text : t.textDim, Font::Body, TextAlign::Left);

    // switch track on the right
    float trackW = 42, trackH = 22;
    Rect track = { r.right() - trackW, r.cy() - trackH / 2, trackW, trackH };
    s.knob = approach(s.knob, value ? 1.0f : 0.0f, 22.0f, m_in.dt);
    Color trackCol = t.panelAlt.lerp(t.accent, s.knob);
    m_r.fillRoundRect(track, trackH / 2, trackCol);

    float kR = trackH / 2 - 3;
    float kx = track.x + trackH / 2 + (trackW - trackH) * s.knob;
    if (s.knob > 0.5f)
        m_r.circle(kx, track.cy(), kR + 2.0f, t.accent2.withAlpha(0.35f * s.knob));
    m_r.circle(kx, track.cy(), kR, Color::rgb(255, 255, 255));

    return changed;
}

// ---- slider ------------------------------------------------------------

bool UI::slider(const std::wstring& id, const std::wstring& label, float& value,
                float lo, float hi, const Rect& r, const wchar_t* fmt) {
    const Theme& t = theme();
    WidgetState& s = state(id);

    Rect lblBox = { r.x, r.y, r.w, 16 };
    Rect track  = { r.x, r.y + 20, r.w, 6 };

    bool overTrack = hot({ track.x, track.y - 8, track.w, track.h + 16 });
    if (overTrack && m_in.mousePressed) s.active = true;
    if (!m_in.mouseDown) s.active = false;

    if (s.active) {
        float tnorm = clampf((m_in.mouseX - track.x) / track.w, 0.0f, 1.0f);
        value = lo + (hi - lo) * tnorm;
    }
    s.hover = approach(s.hover, (overTrack || s.active) ? 1.0f : 0.0f, 16.0f, m_in.dt);

    float norm = (hi > lo) ? clampf((value - lo) / (hi - lo), 0.0f, 1.0f) : 0.0f;

    // label + value readout
    m_r.text(label, lblBox, t.textDim, Font::Small, TextAlign::Left);
    wchar_t buf[64];
    swprintf(buf, 64, fmt, value);
    m_r.text(buf, lblBox, t.accent2, Font::Small, TextAlign::Right);

    // track + fill + knob
    m_r.fillRoundRect(track, 3, t.panelAlt);
    Rect fill = { track.x, track.y, track.w * norm, track.h };
    m_r.gradientRoundRect(fill, 3, t.accent2, t.accent);
    float kx = track.x + track.w * norm;
    float kr = 7.0f + 2.0f * s.hover;
    m_r.circle(kx, track.cy(), kr + 3, t.accent.withAlpha(0.30f * s.hover));
    m_r.circle(kx, track.cy(), kr, Color::rgb(255, 255, 255));

    return s.active;
}

// ---- nav-rail item -----------------------------------------------------

bool UI::railItem(const std::wstring& id, const std::wstring& glyph,
                  const Rect& r, bool selected) {
    const Theme& t = theme();
    WidgetState& s = state(id);
    bool isHot = hot(r);
    animHoverPress(s, isHot, m_in.mouseDown);
    s.knob = approach(s.knob, selected ? 1.0f : 0.0f, 18.0f, m_in.dt);

    if (selected || s.hover > 0.01f) {
        Rect bg = r.inset(6.0f);
        Color c = t.accent.withAlpha(0.10f + 0.22f * std::max(s.knob, s.hover));
        m_r.fillRoundRect(bg, 10.0f, c);
    }
    // active indicator bar on the left edge
    if (s.knob > 0.01f) {
        float h = r.h * 0.46f * s.knob;
        Rect bar = { r.x + 2, r.cy() - h / 2, 3.5f, h };
        m_r.fillRoundRect(bar, 2, t.accent2);
    }
    Color ic = t.textDim.lerp(t.accent2, std::max(s.knob, s.hover));
    m_r.text(glyph, r, ic, Font::Icon, TextAlign::Center);
    return isHot && m_in.mouseReleased;
}

// ---- scroll region -----------------------------------------------------

Rect UI::beginScroll(const std::wstring& id, const Rect& view, float contentHeight) {
    WidgetState& s = state(id);
    float maxScroll = std::max(0.0f, contentHeight - view.h);

    if (hot(view) && m_in.wheel != 0.0f)
        s.scroll -= m_in.wheel * 0.4f;       // wheel delta already scaled by caller
    s.scroll = clampf(s.scroll, 0.0f, maxScroll);

    m_scrollId = id;
    m_scrollView = view;
    m_r.pushClip(view);

    // scrollbar track (only if overflow)
    if (maxScroll > 0.5f) {
        const Theme& t = theme();
        float barH = std::max(28.0f, view.h * (view.h / contentHeight));
        float barY = view.y + (view.h - barH) * (s.scroll / maxScroll);
        Rect bar = { view.right() - 5, barY, 3, barH };
        m_r.fillRoundRect(bar, 2, t.accent.withAlpha(0.7f));
    }
    return { view.x, view.y - s.scroll, view.w, contentHeight };
}

void UI::endScroll() {
    m_r.popClip();
    m_scrollId.clear();
}

// ---- text input --------------------------------------------------------

bool UI::textInput(const std::wstring& id, std::wstring& buffer, const Rect& r,
                   const std::wstring& placeholder) {
    const Theme& t = theme();
    WidgetState& s = state(id);
    bool isHot = hot(r);

    if (m_in.mousePressed) s.active = isHot;   // click to focus / blur

    if (s.active) {
        if (!m_in.typed.empty()) buffer += m_in.typed;
        if (m_in.backspace && !buffer.empty()) buffer.pop_back();
    }

    Color border = s.active ? t.accent : t.stroke;
    m_r.fillRoundRect(r, 8.0f, t.panelAlt);
    m_r.strokeRoundRect(r, 8.0f, border, s.active ? 1.5f : 1.0f);

    Rect txt = { r.x + 10, r.y, r.w - 20, r.h };
    if (buffer.empty() && !s.active) {
        m_r.text(placeholder, txt, t.textFaint, Font::Body, TextAlign::Left);
    } else {
        std::wstring shown = buffer;
        // blink caret when focused
        if (s.active) {
            s.knob += m_in.dt;
            if (std::fmod(s.knob, 1.0f) < 0.5f) shown += L"|";
        }
        m_r.text(shown, txt, t.text, Font::Body, TextAlign::Left);
    }

    if (s.active && m_in.enter) return true;
    return false;
}

} // namespace volt
