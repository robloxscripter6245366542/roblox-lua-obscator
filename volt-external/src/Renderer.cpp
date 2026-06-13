// Renderer.cpp — Direct2D backend implementation.
#include "Renderer.h"
#include <algorithm>

#pragma comment(lib, "d2d1.lib")
#pragma comment(lib, "dwrite.lib")

namespace volt {

static D2D1_COLOR_F d2c(const Color& c) {
    return D2D1::ColorF(c.r, c.g, c.b, c.a);
}

bool Renderer::init(HWND hwnd) {
    m_hwnd = hwnd;

    if (FAILED(D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &m_d2d)))
        return false;

    if (FAILED(DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED,
            __uuidof(IDWriteFactory), reinterpret_cast<IUnknown**>(&m_dw))))
        return false;

    RECT rc;
    GetClientRect(hwnd, &rc);
    m_w = std::max<UINT>(1, rc.right - rc.left);
    m_h = std::max<UINT>(1, rc.bottom - rc.top);

    HRESULT hr = m_d2d->CreateHwndRenderTarget(
        D2D1::RenderTargetProperties(),
        D2D1::HwndRenderTargetProperties(hwnd, D2D1::SizeU(m_w, m_h),
                                         D2D1_PRESENT_OPTIONS_NONE),
        &m_rt);
    if (FAILED(hr)) return false;

    m_rt->SetAntialiasMode(D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
    m_rt->CreateSolidColorBrush(D2D1::ColorF(D2D1::ColorF::White), &m_brush);

    auto mkFont = [&](const wchar_t* family, float size, DWRITE_FONT_WEIGHT w,
                      IDWriteTextFormat** out) {
        m_dw->CreateTextFormat(family, nullptr, w, DWRITE_FONT_STYLE_NORMAL,
                               DWRITE_FONT_STRETCH_NORMAL, size, L"en-us", out);
        if (*out) {
            (*out)->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
            (*out)->SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
        }
    };
    mkFont(L"Segoe UI",          14.0f, DWRITE_FONT_WEIGHT_NORMAL,    &m_fBody);
    mkFont(L"Segoe UI",          12.0f, DWRITE_FONT_WEIGHT_NORMAL,    &m_fSmall);
    mkFont(L"Segoe UI Semibold", 17.0f, DWRITE_FONT_WEIGHT_SEMI_BOLD, &m_fTitle);
    mkFont(L"Consolas",          13.0f, DWRITE_FONT_WEIGHT_NORMAL,    &m_fMono);
    mkFont(L"Segoe UI Symbol",   16.0f, DWRITE_FONT_WEIGHT_NORMAL,    &m_fIcon);
    return true;
}

void Renderer::shutdown() {
    auto rel = [](auto*& p) { if (p) { p->Release(); p = nullptr; } };
    rel(m_fBody); rel(m_fSmall); rel(m_fTitle); rel(m_fMono); rel(m_fIcon);
    rel(m_brush); rel(m_rt); rel(m_dw); rel(m_d2d);
}

void Renderer::resize(UINT w, UINT h) {
    m_w = std::max<UINT>(1, w);
    m_h = std::max<UINT>(1, h);
    if (m_rt) m_rt->Resize(D2D1::SizeU(m_w, m_h));
}

ID2D1SolidColorBrush* Renderer::brush(const Color& c) {
    m_brush->SetColor(d2c(c));
    return m_brush;
}

IDWriteTextFormat* Renderer::format(Font f) {
    switch (f) {
        case Font::Small: return m_fSmall;
        case Font::Title: return m_fTitle;
        case Font::Mono:  return m_fMono;
        case Font::Icon:  return m_fIcon;
        default:          return m_fBody;
    }
}

bool Renderer::beginFrame(const Color& clear) {
    if (!m_rt) return false;
    m_rt->BeginDraw();
    m_rt->Clear(d2c(clear));
    return true;
}

void Renderer::endFrame() {
    if (!m_rt) return;
    HRESULT hr = m_rt->EndDraw();
    if (hr == D2DERR_RECREATE_TARGET) {
        // Device lost (display change / GPU reset). Drop the target; init()
        // path will rebuild on next frame via the app's recovery.
        if (m_rt) { m_rt->Release(); m_rt = nullptr; }
    }
}

void Renderer::fillRect(const Rect& r, const Color& c) {
    m_rt->FillRectangle(D2D1::RectF(r.x, r.y, r.right(), r.bottom()), brush(c));
}

void Renderer::fillRoundRect(const Rect& r, float radius, const Color& c) {
    m_rt->FillRoundedRectangle(
        D2D1::RoundedRect(D2D1::RectF(r.x, r.y, r.right(), r.bottom()), radius, radius),
        brush(c));
}

void Renderer::strokeRoundRect(const Rect& r, float radius, const Color& c, float t) {
    m_rt->DrawRoundedRectangle(
        D2D1::RoundedRect(D2D1::RectF(r.x, r.y, r.right(), r.bottom()), radius, radius),
        brush(c), t);
}

void Renderer::line(float x0, float y0, float x1, float y1, const Color& c, float t) {
    m_rt->DrawLine(D2D1::Point2F(x0, y0), D2D1::Point2F(x1, y1), brush(c), t);
}

void Renderer::circle(float cx, float cy, float radius, const Color& c) {
    m_rt->FillEllipse(D2D1::Ellipse(D2D1::Point2F(cx, cy), radius, radius), brush(c));
}

void Renderer::gradientRoundRect(const Rect& r, float radius,
                                 const Color& top, const Color& bottom) {
    // Build a transient linear gradient brush. Cheap enough for our element
    // counts; keeps the renderer stateless between calls.
    ID2D1GradientStopCollection* stops = nullptr;
    D2D1_GRADIENT_STOP g[2] = {
        { 0.0f, d2c(top) },
        { 1.0f, d2c(bottom) },
    };
    if (FAILED(m_rt->CreateGradientStopCollection(g, 2, &stops))) {
        fillRoundRect(r, radius, top);
        return;
    }
    ID2D1LinearGradientBrush* lg = nullptr;
    m_rt->CreateLinearGradientBrush(
        D2D1::LinearGradientBrushProperties(D2D1::Point2F(r.x, r.y),
                                            D2D1::Point2F(r.x, r.bottom())),
        stops, &lg);
    if (lg) {
        m_rt->FillRoundedRectangle(
            D2D1::RoundedRect(D2D1::RectF(r.x, r.y, r.right(), r.bottom()), radius, radius),
            lg);
        lg->Release();
    }
    stops->Release();
}

void Renderer::dropShadow(const Rect& r, float radius, const Color& c, float spread) {
    // Layered translucent rounded rects fanning outward — a quick soft shadow
    // without a Gaussian blur effect pass.
    const int layers = 6;
    for (int i = layers; i >= 1; --i) {
        float t = static_cast<float>(i) / layers;
        float grow = spread * t;
        Rect rr = { r.x - grow, r.y - grow + 3.0f, r.w + grow * 2, r.h + grow * 2 };
        Color cc = c.withAlpha(c.a * (1.0f - t) * 0.5f);
        fillRoundRect(rr, radius + grow, cc);
    }
}

void Renderer::text(const std::wstring& s, const Rect& box, const Color& c,
                    Font font, TextAlign align, bool vcenter) {
    IDWriteTextFormat* fmt = format(font);
    if (!fmt) return;
    switch (align) {
        case TextAlign::Center: fmt->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER); break;
        case TextAlign::Right:  fmt->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_TRAILING); break;
        default:                fmt->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_LEADING); break;
    }
    fmt->SetParagraphAlignment(vcenter ? DWRITE_PARAGRAPH_ALIGNMENT_CENTER
                                       : DWRITE_PARAGRAPH_ALIGNMENT_NEAR);
    m_rt->DrawText(s.c_str(), static_cast<UINT32>(s.size()), fmt,
                   D2D1::RectF(box.x, box.y, box.right(), box.bottom()),
                   brush(c), D2D1_DRAW_TEXT_OPTIONS_CLIP);
}

float Renderer::measure(const std::wstring& s, Font font) {
    IDWriteTextFormat* fmt = format(font);
    if (!fmt) return 0.0f;
    IDWriteTextLayout* layout = nullptr;
    if (FAILED(m_dw->CreateTextLayout(s.c_str(), static_cast<UINT32>(s.size()),
                                      fmt, 4096.0f, 64.0f, &layout)))
        return 0.0f;
    DWRITE_TEXT_METRICS tm{};
    layout->GetMetrics(&tm);
    layout->Release();
    return tm.widthIncludingTrailingWhitespace;
}

void Renderer::pushClip(const Rect& r) {
    m_rt->PushAxisAlignedClip(D2D1::RectF(r.x, r.y, r.right(), r.bottom()),
                              D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
}

void Renderer::popClip() {
    m_rt->PopAxisAlignedClip();
}

} // namespace volt
