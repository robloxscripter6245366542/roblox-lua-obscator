// Store.cpp — capture store + stats.
#include "App.h"
#include <algorithm>

namespace volt {

void Store::push(std::deque<RemoteCall>& list, const RemoteCall& c, bool merge) {
    if (merge && !list.empty()) {
        RemoteCall& last = list.front();
        if (last.name == c.name && last.method == c.method && last.args == c.args) {
            last.count += c.count;
            last.t = c.t;
            return;
        }
    }
    list.push_front(c);
    while (list.size() > maxLog) list.pop_back();
}

void Store::ingest(const std::vector<RemoteCall>& calls, bool merge) {
    for (const auto& c : calls) {
        if (isBlocked(c.name)) continue;
        m_totals[c.name] += c.count;
        m_grand += c.count;
        if (c.dir == Dir::Out) push(m_out, c, merge);
        else                   push(m_in, c, merge);
    }
}

void Store::clear() {
    m_out.clear();
    m_in.clear();
    m_totals.clear();
    m_grand = 0;
}

bool Store::isBlocked(const std::wstring& name) const {
    return std::find(m_blocked.begin(), m_blocked.end(), name) != m_blocked.end();
}

void Store::toggleBlock(const std::wstring& name) {
    auto it = std::find(m_blocked.begin(), m_blocked.end(), name);
    if (it == m_blocked.end()) m_blocked.push_back(name);
    else                       m_blocked.erase(it);
}

std::vector<std::pair<std::wstring, int>> Store::top(size_t n) const {
    std::vector<std::pair<std::wstring, int>> v(m_totals.begin(), m_totals.end());
    std::sort(v.begin(), v.end(),
              [](auto& a, auto& b) { return a.second > b.second; });
    if (v.size() > n) v.resize(n);
    return v;
}

void Store::seedDemo() {
    auto mk = [](Dir d, const wchar_t* n, const wchar_t* m, const wchar_t* rt,
                 const wchar_t* a, const wchar_t* src, int cnt, bool exec) {
        RemoteCall c;
        c.dir = d; c.name = n; c.method = m; c.rtype = rt;
        c.args = a; c.source = src; c.count = cnt; c.fromExec = exec;
        return c;
    };
    std::vector<RemoteCall> demo = {
        mk(Dir::Out, L"HitDetectionHeartbeat", L"FireServer", L"RemoteEvent",
           L"(no args)", L"LocalScript.Heartbeat:42", 318, false),
        mk(Dir::Out, L"RequestSwing", L"FireServer", L"RemoteEvent",
           L"\"Heavy\", Vector3(0, 0, -1)", L"CombatClient:121", 27, false),
        mk(Dir::In,  L"RoundTimerUpdate", L"OnClientEvent", L"RemoteEvent",
           L"\"DODGE!\", false", L"server", 4, false),
        mk(Dir::Out, L"PurchaseItem", L"InvokeServer", L"RemoteFunction",
           L"\"sword_legendary\", 1", L"ShopUI:88", 1, false),
        mk(Dir::In,  L"PlaySound", L"OnClientEvent", L"RemoteEvent",
           L"SoundEffects.WallHit", L"server", 12, false),
        mk(Dir::Out, L"AdminCommand", L"FireServer", L"RemoteEvent",
           L"\"kick\", \"player\"", L"exploit:1", 1, true),
    };
    ingest(demo, false);
}

} // namespace volt
