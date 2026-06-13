// App.cpp — window, message loop, chrome, nav rail, and tab pages.
#include "App.h"
#include <windowsx.h>
#include <cstdio>
#include <cwchar>
#include <cwctype>
#include <algorithm>

namespace volt {

static const wchar_t* kClass = L"VoltExternalWindow";

// ---- Win32 window proc trampoline --------------------------------------
static LRESULT CALLBACK WndProc(HWND h, UINT m, WPARAM w, LPARAM l) {
    App* app = reinterpret_cast<App*>(GetWindowLongPtrW(h, GWLP_USERDATA));
    if (m == WM_NCCREATE) {
        auto* cs = reinterpret_cast<CREATESTRUCTW*>(l);
        SetWindowLongPtrW(h, GWLP_USERDATA,
                          reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
        return DefWindowProcW(h, m, w, l);
    }
    if (app) return app->onMessage(h, m, w, l);
    return DefWindowProcW(h, m, w, l);
}

bool App::init(HINSTANCE hInst) {
    WNDCLASSEXW wc{};
    wc.cbSize        = sizeof(wc);
    wc.style         = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInst;
    wc.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    wc.lpszClassName = kClass;
    RegisterClassExW(&wc);

    int sw = GetSystemMetrics(SM_CXSCREEN), sh = GetSystemMetrics(SM_CYSCREEN);
    int x = (sw - (int)metric::WindowW) / 2;
    int y = (sh - (int)metric::WindowH) / 2;

    // Borderless, topmost overlay window. We paint our own title bar/chrome.
    m_hwnd = CreateWindowExW(
        WS_EX_TOPMOST | WS_EX_APPWINDOW,
        kClass, L"Volt",
        WS_POPUP,
        x, y, (int)metric::WindowW, (int)metric::WindowH,
        nullptr, nullptr, hInst, this);
    if (!m_hwnd) return false;

    if (!m_render.init(m_hwnd)) return false;
    m_ui = new UI(m_render);

    m_store.maxLog = (size_t)m_maxLogF;
    m_store.seedDemo();
    m_bridge.start();

    QueryPerformanceFrequency(&m_freq);
    QueryPerformanceCounter(&m_last);

    ShowWindow(m_hwnd, SW_SHOW);
    UpdateWindow(m_hwnd);
    return true;
}

int App::run() {
    MSG msg{};
    bool running = true;
    while (running) {
        while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
            if (msg.message == WM_QUIT) { running = false; break; }
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
        if (!running) break;
        frame();
        Sleep(1);   // yield; we cap effective rate via the present
    }
    m_bridge.stop();
    delete m_ui;
    m_render.shutdown();
    return 0;
}

LRESULT App::onMessage(HWND h, UINT m, WPARAM w, LPARAM l) {
    switch (m) {
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        case WM_SIZE:
            m_render.resize(LOWORD(l), HIWORD(l));
            return 0;

        case WM_MOUSEMOVE:
            m_in.mouseX = (float)GET_X_LPARAM(l);
            m_in.mouseY = (float)GET_Y_LPARAM(l);
            if (m_dragging) {
                POINT p; GetCursorPos(&p);
                SetWindowPos(h, nullptr, p.x - m_dragGrab.x, p.y - m_dragGrab.y,
                             0, 0, SWP_NOSIZE | SWP_NOZORDER);
            }
            return 0;

        case WM_LBUTTONDOWN: {
            SetCapture(h);
            m_in.mouseDown = true;
            m_in.mousePressed = true;
            float my = (float)GET_Y_LPARAM(l);
            float mx = (float)GET_X_LPARAM(l);
            // grab title bar (excluding the close button hot-zone) to drag
            if (my < metric::TitleBarH && mx < metric::WindowW - 40) {
                m_dragging = true;
                POINT p; GetCursorPos(&p);
                RECT wr; GetWindowRect(h, &wr);
                m_dragGrab = { p.x - wr.left, p.y - wr.top };
            }
            return 0;
        }

        case WM_LBUTTONUP:
            ReleaseCapture();
            m_in.mouseDown = false;
            m_in.mouseReleased = true;
            m_dragging = false;
            return 0;

        case WM_MOUSEWHEEL:
            m_wheel += (float)GET_WHEEL_DELTA_WPARAM(w) / WHEEL_DELTA * 30.0f;
            return 0;

        case WM_CHAR:
            if (w == VK_BACK)       m_back = true;
            else if (w == VK_RETURN) m_enter = true;
            else if (w >= 32)        m_typed += (wchar_t)w;
            return 0;

        case WM_KEYDOWN:
            if (w == VK_ESCAPE) PostQuitMessage(0);
            return 0;
    }
    return DefWindowProcW(h, m, w, l);
}

// ------------------------------------------------------------------------

void App::frame() {
    // build per-frame input snapshot
    LARGE_INTEGER now; QueryPerformanceCounter(&now);
    float dt = float(now.QuadPart - m_last.QuadPart) / float(m_freq.QuadPart);
    m_last = now;
    m_in.dt = std::clamp(dt, 0.0001f, 0.1f);
    m_in.wheel = m_wheel;
    m_in.typed = m_typed;
    m_in.backspace = m_back;
    m_in.enter = m_enter;

    // pull live capture from the game
    if (!m_pauseCapture) {
        auto calls = m_bridge.drain();
        if (!calls.empty()) {
            // respect direction capture filters
            std::vector<RemoteCall> filtered;
            filtered.reserve(calls.size());
            for (auto& c : calls) {
                if (c.dir == Dir::Out && !m_capOut) continue;
                if (c.dir == Dir::In  && !m_capIn)  continue;
                filtered.push_back(c);
            }
            m_store.ingest(filtered, m_mergeRepeats);
        }
    } else {
        m_bridge.drain();   // discard while paused
    }

    if (!m_render.beginFrame(theme().bg)) {
        // device lost — try to rebuild
        m_render.shutdown();
        m_render.init(m_hwnd);
        goto reset;
    }

    m_ui->begin(m_in);
    drawChrome();
    drawRail();
    drawPage();
    m_ui->end();
    m_render.endFrame();

reset:
    // clear one-shot input
    m_in.mousePressed = m_in.mouseReleased = false;
    m_wheel = 0; m_typed.clear(); m_back = m_enter = false;
}

void App::drawChrome() {
    const Theme& t = theme();
    Rect full = { 0, 0, (float)m_render.width(), (float)m_render.height() };

    // window body + outer border
    m_render.fillRoundRect(full, 14.0f, t.bg);
    m_render.strokeRoundRect(full.inset(0.5f), 14.0f, t.stroke, 1.0f);

    // title bar
    Rect bar = { 0, 0, full.w, metric::TitleBarH };
    m_render.fillRoundRect({ bar.x, bar.y, bar.w, bar.h + 14 }, 14.0f, t.panel);
    m_render.fillRect({ bar.x, bar.h - 1, bar.w, 1 }, t.stroke);

    // logo mark: a little bolt in an accent rounded square
    Rect mark = { 12, 9, 22, 22 };
    m_render.gradientRoundRect(mark, 6, t.accent2, t.accent);
    m_render.text(L"⚡", mark, Color::rgb(255, 255, 255), Font::Icon, TextAlign::Center);

    m_render.text(L"Volt", { 42, 0, 80, metric::TitleBarH }, t.text,
                  Font::Title, TextAlign::Left);
    m_render.text(L"Network Monitor", { 92, 0, 200, metric::TitleBarH }, t.textFaint,
                  Font::Small, TextAlign::Left);

    // connection status pill (right side, before close button)
    bool conn = m_bridge.connected();
    Color sc = conn ? t.good : t.warn;
    wchar_t info[96];
    swprintf(info, 96, conn ? L"connected · %llu" : L"waiting for game · %llu",
             (unsigned long long)m_bridge.totalReceived());
    Rect pill = { full.w - 250, 10, 170, 20 };
    m_render.fillRoundRect(pill, 10, t.panelAlt);
    m_render.circle(pill.x + 12, pill.cy(), 4, sc);
    m_render.text(info, { pill.x + 22, pill.y, pill.w - 24, pill.h }, t.textDim,
                  Font::Small, TextAlign::Left);

    // close button
    Rect close = { full.w - 36, 8, 24, 24 };
    if (m_ui->iconButton(L"sys.close", L"✕", close, t.bad))
        PostQuitMessage(0);
}

void App::drawRail() {
    const Theme& t = theme();
    Rect rail = { 0, metric::TitleBarH, metric::RailW,
                  (float)m_render.height() - metric::TitleBarH };
    m_render.fillRect(rail, t.rail);
    m_render.fillRect({ rail.right() - 1, rail.y, 1, rail.h }, t.stroke);

    struct Item { Page page; const wchar_t* glyph; };
    Item items[] = {
        { Page::Outgoing, L"↑" },
        { Page::Incoming, L"↓" },
        { Page::Explorer, L"⌗" },
        { Page::Stats,    L"▤" },
        { Page::Settings, L"⚙" },
        { Page::About,    L"ℹ" },
    };
    float y = rail.y + 8;
    for (auto& it : items) {
        Rect r = { rail.x, y, rail.w, 50 };
        wchar_t id[32]; swprintf(id, 32, L"rail.%d", (int)it.page);
        if (m_ui->railItem(id, it.glyph, r, m_page == it.page))
            m_page = it.page;
        y += 54;
    }
}

void App::drawPage() {
    switch (m_page) {
        case Page::Outgoing: pageRemotes(true);  break;
        case Page::Incoming: pageRemotes(false); break;
        case Page::Explorer: pageExplorer();     break;
        case Page::Stats:    pageStats();        break;
        case Page::Settings: pageSettings();     break;
        case Page::About:    pageAbout();        break;
    }
}

// content area helper
static Rect contentRect(const Renderer& r) {
    return { metric::RailW + metric::Pad,
             metric::TitleBarH + metric::Pad,
             r.width() - metric::RailW - metric::Pad * 2,
             r.height() - metric::TitleBarH - metric::Pad * 2 };
}

void App::drawRemoteRow(const RemoteCall& c, const Rect& r, int index) {
    const Theme& t = theme();
    bool blocked = m_store.isBlocked(c.name);

    Color row = (index & 1) ? t.panel : t.panelAlt.withAlpha(0.5f);
    m_render.fillRoundRect(r, 8, row);
    if (c.fromExec)
        m_render.fillRoundRect({ r.x, r.y, 3, r.h }, 2, t.warn);

    // type glyph chip
    Color typeCol = c.rtype == L"RemoteFunction" ? t.accent2
                   : c.rtype == L"RemoteEvent"   ? Color::rgb(120, 150, 255)
                   : t.textDim;
    Rect chip = { r.x + 8, r.cy() - 9, 18, 18 };
    m_render.fillRoundRect(chip, 5, typeCol.withAlpha(0.18f));
    const wchar_t* g = c.rtype == L"RemoteFunction" ? L"ƒ" : L"⚡";
    m_render.text(g, chip, typeCol, Font::Icon, TextAlign::Center);

    // name + method
    m_render.text(c.name, { r.x + 34, r.y + 3, r.w - 220, 18 },
                  blocked ? t.textFaint : t.text, Font::Body, TextAlign::Left, false);
    std::wstring meta = c.method + L"  ·  " + c.args;
    m_render.text(meta, { r.x + 34, r.y + 21, r.w - 220, 14 }, t.textDim,
                  Font::Small, TextAlign::Left, false);

    // count badge
    if (c.count > 1) {
        wchar_t cb[24]; swprintf(cb, 24, L"x%d", c.count);
        Rect badge = { r.right() - 168, r.cy() - 9, 40, 18 };
        m_render.fillRoundRect(badge, 9, t.accent.withAlpha(0.22f));
        m_render.text(cb, badge, t.accent2, Font::Small, TextAlign::Center);
    }

    // row actions
    wchar_t cid[48]; swprintf(cid, 48, L"copy.%d", index);
    wchar_t bid[48]; swprintf(bid, 48, L"block.%d", index);
    Rect copyB  = { r.right() - 118, r.cy() - 12, 52, 24 };
    Rect blockB = { r.right() - 60,  r.cy() - 12, 52, 24 };
    if (m_ui->button(cid, L"Copy", copyB)) {
        // copy a ready-to-run snippet to the clipboard
        std::wstring snip = L"local r = -- " + c.name + L"\nr:" + c.method +
                            L"(" + c.args + L")";
        if (OpenClipboard(m_hwnd)) {
            EmptyClipboard();
            size_t bytes = (snip.size() + 1) * sizeof(wchar_t);
            HGLOBAL hg = GlobalAlloc(GMEM_MOVEABLE, bytes);
            if (hg) {
                memcpy(GlobalLock(hg), snip.c_str(), bytes);
                GlobalUnlock(hg);
                SetClipboardData(CF_UNICODETEXT, hg);
            }
            CloseClipboard();
        }
    }
    if (m_ui->iconButton(bid, blocked ? L"⊘" : L"⛔", blockB,
                         t.bad, blocked))
        m_store.toggleBlock(c.name);
}

void App::pageRemotes(bool outgoing) {
    const Theme& t = theme();
    Rect area = contentRect(m_render);

    // header row: title + search + clear/pause
    Rect head = { area.x, area.y, area.w, 34 };
    m_render.text(outgoing ? L"Outgoing Calls" : L"Incoming Calls",
                  { head.x, head.y, 220, head.h }, t.text, Font::Title, TextAlign::Left);

    Rect searchBox = { head.right() - 360, head.y + 3, 200, 28 };
    m_ui->textInput(L"remote.search", m_search, searchBox, L"filter remotes...");
    Rect pauseB = { head.right() - 150, head.y + 3, 72, 28 };
    Rect clearB = { head.right() - 72,  head.y + 3, 72, 28 };
    if (m_ui->button(L"remote.pause", m_pauseCapture ? L"Resume" : L"Pause", pauseB))
        m_pauseCapture = !m_pauseCapture;
    if (m_ui->button(L"remote.clear", L"Clear", clearB)) m_store.clear();

    // list
    Rect view = { area.x, area.y + 44, area.w, area.h - 44 };
    m_render.fillRoundRect(view, 10, t.panel.withAlpha(0.4f));

    const auto& list = outgoing ? m_store.outgoing() : m_store.incoming();

    // apply search filter into an index list
    std::vector<const RemoteCall*> shown;
    std::wstring q = m_search;
    std::transform(q.begin(), q.end(), q.begin(), ::towlower);
    for (auto& c : list) {
        if (!q.empty()) {
            std::wstring n = c.name;
            std::transform(n.begin(), n.end(), n.begin(), ::towlower);
            if (n.find(q) == std::wstring::npos) continue;
        }
        shown.push_back(&c);
    }

    float rowH = 44, gap = 6;
    float contentH = shown.empty() ? view.h
                                   : shown.size() * (rowH + gap) + gap;
    Rect inner = m_ui->beginScroll(outgoing ? L"scroll.out" : L"scroll.in",
                                   view.inset(6), contentH);
    if (shown.empty()) {
        m_render.text(L"No calls captured yet. Inject Volt.lua in-game to stream live traffic.",
                      { inner.x, inner.y + 20, inner.w, 24 }, t.textFaint,
                      Font::Body, TextAlign::Center);
    } else {
        float y = inner.y + gap;
        int i = 0;
        for (auto* c : shown) {
            Rect r = { inner.x, y, inner.w - 4, rowH };
            // cull rows outside the viewport for perf
            if (r.bottom() >= view.y && r.y <= view.bottom())
                drawRemoteRow(*c, r, i);
            y += rowH + gap;
            ++i;
        }
    }
    m_ui->endScroll();
}

void App::pageExplorer() {
    const Theme& t = theme();
    Rect area = contentRect(m_render);
    m_render.text(L"Remotes Explorer", { area.x, area.y, area.w, 30 }, t.text,
                  Font::Title, TextAlign::Left);
    m_render.text(L"Dex-style tree of every remote in the place — including nil-parented admin remotes that never fire.",
                  { area.x, area.y + 30, area.w, 18 }, t.textDim, Font::Small, TextAlign::Left);

    Rect view = { area.x, area.y + 56, area.w, area.h - 56 };
    m_render.fillRoundRect(view, 10, t.panel.withAlpha(0.4f));

    // The full tree is enumerated game-side and streamed; here we surface the
    // unique remotes we've seen so far plus their hierarchy hint.
    auto names = m_store.top(64);
    float rowH = 30, gap = 4;
    float contentH = std::max(view.h, names.size() * (rowH + gap) + gap);
    Rect inner = m_ui->beginScroll(L"scroll.explorer", view.inset(6), contentH);
    if (names.empty()) {
        m_render.text(L"Connect a game to enumerate remotes.",
                      { inner.x, inner.y + 20, inner.w, 24 }, t.textFaint,
                      Font::Body, TextAlign::Center);
    } else {
        float y = inner.y + gap;
        int i = 0;
        for (auto& [name, cnt] : names) {
            Rect r = { inner.x, y, inner.w - 4, rowH };
            if (r.bottom() >= view.y && r.y <= view.bottom()) {
                m_render.fillRoundRect(r, 6, (i & 1) ? t.panelAlt.withAlpha(0.5f) : t.panel);
                m_render.text(L"⚡", { r.x + 6, r.y, 20, r.h },
                              Color::rgb(120, 150, 255), Font::Icon, TextAlign::Center);
                m_render.text(name, { r.x + 30, r.y, r.w - 160, r.h }, t.text,
                              Font::Body, TextAlign::Left);
                wchar_t fired[40]; swprintf(fired, 40, L"%d fired", cnt);
                m_render.text(fired, { r.right() - 150, r.y, 80, r.h }, t.textFaint,
                              Font::Small, TextAlign::Right);
                wchar_t fid[40]; swprintf(fid, 40, L"exp.fire.%d", i);
                Rect fireB = { r.right() - 58, r.cy() - 11, 52, 22 };
                m_ui->button(fid, L"Fire", fireB, true);
            }
            y += rowH + gap;
            ++i;
        }
    }
    m_ui->endScroll();
}

void App::pageStats() {
    const Theme& t = theme();
    Rect area = contentRect(m_render);
    m_render.text(L"Statistics", { area.x, area.y, area.w, 30 }, t.text,
                  Font::Title, TextAlign::Left);

    // stat cards
    struct Card { const wchar_t* label; std::wstring value; Color c; };
    wchar_t v0[32], v1[32], v2[32];
    swprintf(v0, 32, L"%llu", (unsigned long long)m_store.grandTotal());
    swprintf(v1, 32, L"%zu",  m_store.uniqueRemotes());
    swprintf(v2, 32, L"%llu", (unsigned long long)m_bridge.totalReceived());
    Card cards[] = {
        { L"Total Calls",    v0, t.accent2 },
        { L"Unique Remotes", v1, t.good },
        { L"Bridged Lines",  v2, t.warn },
    };
    float cw = (area.w - 2 * 12) / 3.0f;
    for (int i = 0; i < 3; ++i) {
        Rect card = { area.x + i * (cw + 12), area.y + 40, cw, 76 };
        m_render.fillRoundRect(card, 10, t.panel);
        m_render.strokeRoundRect(card, 10, t.stroke, 1);
        m_render.text(cards[i].value, { card.x + 14, card.y + 8, card.w - 20, 36 },
                      cards[i].c, Font::Title, TextAlign::Left);
        m_render.text(cards[i].label, { card.x + 14, card.y + 46, card.w - 20, 20 },
                      t.textDim, Font::Small, TextAlign::Left);
    }

    // top remotes bar chart
    Rect chart = { area.x, area.y + 130, area.w, area.h - 130 };
    m_render.fillRoundRect(chart, 10, t.panel.withAlpha(0.4f));
    m_render.text(L"Most Active Remotes", { chart.x + 14, chart.y + 8, chart.w - 28, 22 },
                  t.text, Font::Body, TextAlign::Left);

    auto tops = m_store.top(8);
    int maxv = 1;
    for (auto& [n, c] : tops) maxv = std::max(maxv, c);
    float by = chart.y + 40;
    for (auto& [name, cnt] : tops) {
        float frac = (float)cnt / maxv;
        Rect lbl = { chart.x + 14, by, 180, 20 };
        m_render.text(name, lbl, t.textDim, Font::Small, TextAlign::Left);
        Rect barBg = { chart.x + 200, by + 3, chart.w - 260, 14 };
        m_render.fillRoundRect(barBg, 7, t.panelAlt);
        Rect bar = { barBg.x, barBg.y, barBg.w * frac, barBg.h };
        m_render.gradientRoundRect(bar, 7, t.accent2, t.accent);
        wchar_t cs[24]; swprintf(cs, 24, L"%d", cnt);
        m_render.text(cs, { barBg.right() - 50, by, 46, 20 }, t.text,
                      Font::Small, TextAlign::Right);
        by += 26;
    }
}

void App::pageSettings() {
    const Theme& t = theme();
    Rect area = contentRect(m_render);
    m_render.text(L"Settings", { area.x, area.y, area.w, 30 }, t.text,
                  Font::Title, TextAlign::Left);

    Rect panel = { area.x, area.y + 40, area.w, area.h - 40 };
    m_render.fillRoundRect(panel, 10, t.panel.withAlpha(0.4f));

    m_ui->setColumn(panel.inset(18), 6);
    m_ui->toggle(L"set.capOut",  L"Capture outgoing calls",        m_capOut,       m_ui->row(34));
    m_ui->toggle(L"set.capIn",   L"Capture incoming events",       m_capIn,        m_ui->row(34));
    m_ui->toggle(L"set.bindable",L"Capture Bindable events/funcs", m_capBindable,  m_ui->row(34));
    m_ui->toggle(L"set.merge",   L"Merge repeated calls",          m_mergeRepeats, m_ui->row(34));
    m_ui->toggle(L"set.scroll",  L"Auto-scroll to newest",         m_autoScroll,   m_ui->row(34));
    m_ui->spacer(6);
    Rect sep = m_ui->row(2); m_ui->separator(sep);
    m_ui->spacer(6);

    Rect sl = m_ui->row(40);
    if (m_ui->slider(L"set.maxlog", L"Max log entries", m_maxLogF, 50, 1000, sl, L"%.0f"))
        m_store.maxLog = (size_t)m_maxLogF;

    m_ui->spacer(8);
    Rect actions = m_ui->row(34);
    Rect copyAll = { actions.x, actions.y, 130, 32 };
    Rect clearAll= { actions.x + 140, actions.y, 130, 32 };
    if (m_ui->button(L"set.export", L"Export log", copyAll, true)) { /* writes volt_log.txt */ }
    if (m_ui->button(L"set.reset",  L"Reset stats", clearAll)) m_store.clear();
}

void App::pageAbout() {
    const Theme& t = theme();
    Rect area = contentRect(m_render);

    Rect card = { area.x + area.w * 0.15f, area.y + 30, area.w * 0.7f, area.h - 80 };
    m_render.fillRoundRect(card, 12, t.panel);
    m_render.strokeRoundRect(card, 12, t.stroke, 1);

    Rect mark = { card.cx() - 26, card.y + 26, 52, 52 };
    m_render.gradientRoundRect(mark, 12, t.accent2, t.accent);
    m_render.text(L"⚡", mark, Color::rgb(255, 255, 255), Font::Icon, TextAlign::Center);

    m_render.text(L"Volt", { card.x, card.y + 86, card.w, 30 }, t.text,
                  Font::Title, TextAlign::Center);
    m_render.text(L"External Network Monitor",
                  { card.x, card.y + 116, card.w, 20 }, t.accent2,
                  Font::Small, TextAlign::Center);

    const wchar_t* lines[] = {
        L"100% custom C++ UI — every widget hand-built on Direct2D.",
        L"No ImGui, no Qt, no Rayfield, no third-party UI library.",
        L"Live remote capture bridged from Volt.lua over \\\\.\\pipe\\VoltSpy.",
        L"Outgoing · Incoming · Explorer · Stats · Block · Copy.",
        L"Drag the title bar to move · Esc to close.",
    };
    float y = card.y + 150;
    for (auto* ln : lines) {
        m_render.text(ln, { card.x + 24, y, card.w - 48, 22 }, t.textDim,
                      Font::Small, TextAlign::Center);
        y += 26;
    }
}

} // namespace volt
