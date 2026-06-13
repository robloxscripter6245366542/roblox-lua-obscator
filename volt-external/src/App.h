// App.h — the Volt application: data store + tab panels on top of the UI.
#pragma once

#include <vector>
#include <string>
#include <deque>
#include "UI.h"
#include "Bridge.h"

namespace volt {

enum class Page { Outgoing, Incoming, Explorer, Stats, Settings, About };

// In-memory store of captured calls + derived stats. Fed by the Bridge.
class Store {
public:
    void ingest(const std::vector<RemoteCall>& calls, bool mergeRepeats);
    void clear();
    void seedDemo();   // a few rows so the UI is alive before a game connects

    const std::deque<RemoteCall>& outgoing() const { return m_out; }
    const std::deque<RemoteCall>& incoming() const { return m_in; }

    bool isBlocked(const std::wstring& name) const;
    void toggleBlock(const std::wstring& name);

    uint64_t grandTotal() const { return m_grand; }
    size_t   uniqueRemotes() const { return m_totals.size(); }
    // Top remotes by call volume, descending. Capped to `n`.
    std::vector<std::pair<std::wstring, int>> top(size_t n) const;

    size_t maxLog = 250;

private:
    void push(std::deque<RemoteCall>& list, const RemoteCall& c, bool merge);

    std::deque<RemoteCall> m_out, m_in;
    std::unordered_map<std::wstring, int> m_totals;
    std::vector<std::wstring> m_blocked;
    uint64_t m_grand = 0;
};

class App {
public:
    bool init(HINSTANCE hInst);
    int  run();

    // Win32 plumbing (called by the static window proc).
    LRESULT onMessage(HWND, UINT, WPARAM, LPARAM);

private:
    void frame();
    void drawChrome();          // title bar + window background + shadow
    void drawRail();            // left nav
    void drawPage();            // dispatch by m_page
    void pageRemotes(bool outgoing);
    void pageExplorer();
    void pageStats();
    void pageSettings();
    void pageAbout();
    void drawRemoteRow(const RemoteCall& c, const Rect& r, int index);

    HWND       m_hwnd = nullptr;
    Renderer   m_render;
    UI*        m_ui = nullptr;
    Store      m_store;
    Bridge     m_bridge;

    Page m_page = Page::Outgoing;

    // window drag
    bool  m_dragging = false;
    POINT m_dragGrab{};

    // input accumulation between frames
    Input m_in;
    std::wstring m_typed;
    bool m_back = false, m_enter = false;
    float m_wheel = 0;
    LARGE_INTEGER m_freq{}, m_last{};

    // settings (live-bound to toggles)
    bool m_capOut = true, m_capIn = true, m_capBindable = true;
    bool m_mergeRepeats = true, m_autoScroll = true, m_pauseCapture = false;
    float m_maxLogF = 250.0f;

    // explorer / search
    std::wstring m_search;
};

} // namespace volt
