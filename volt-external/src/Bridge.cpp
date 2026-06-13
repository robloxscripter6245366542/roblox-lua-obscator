// Bridge.cpp — named-pipe listener + minimal JSON line parser.
#include "Bridge.h"
#include <string>
#include <cstdlib>

namespace volt {

static std::wstring utf8to16(const std::string& s) {
    if (s.empty()) return L"";
    int n = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), nullptr, 0);
    std::wstring w(n, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), &w[0], n);
    return w;
}

// Tiny field extractor: pulls "key":"value" / "key":number out of one JSON
// object line. We control the producer (Volt.lua), so a full JSON parser is
// overkill — this just needs to be robust to the fields Volt emits.
static std::string field(const std::string& json, const std::string& key) {
    std::string pat = "\"" + key + "\"";
    size_t k = json.find(pat);
    if (k == std::string::npos) return "";
    size_t colon = json.find(':', k + pat.size());
    if (colon == std::string::npos) return "";
    size_t i = colon + 1;
    while (i < json.size() && (json[i] == ' ' || json[i] == '\t')) ++i;
    if (i >= json.size()) return "";

    if (json[i] == '"') {
        ++i;
        std::string out;
        while (i < json.size() && json[i] != '"') {
            if (json[i] == '\\' && i + 1 < json.size()) {
                char c = json[i + 1];
                switch (c) {
                    case 'n': out += '\n'; break;
                    case 't': out += '\t'; break;
                    case '"': out += '"';  break;
                    case '\\':out += '\\'; break;
                    default:  out += c;    break;
                }
                i += 2;
            } else {
                out += json[i++];
            }
        }
        return out;
    }
    // bare number / literal
    std::string out;
    while (i < json.size() && json[i] != ',' && json[i] != '}') out += json[i++];
    while (!out.empty() && (out.back() == ' ')) out.pop_back();
    return out;
}

RemoteCall Bridge::parseLine(const std::string& line) {
    RemoteCall c;
    std::string dir = field(line, "dir");
    c.dir      = (dir == "in" || dir == "IN") ? Dir::In : Dir::Out;
    c.name     = utf8to16(field(line, "name"));
    c.method   = utf8to16(field(line, "method"));
    c.rtype    = utf8to16(field(line, "rtype"));
    c.args     = utf8to16(field(line, "args"));
    c.source   = utf8to16(field(line, "source"));
    std::string cnt = field(line, "count");
    c.count    = cnt.empty() ? 1 : atoi(cnt.c_str());
    c.fromExec = field(line, "exec") == "true";
    std::string ts = field(line, "t");
    c.t        = ts.empty() ? 0.0 : atof(ts.c_str());
    return c;
}

void Bridge::start(const std::wstring& streamFile) {
    if (m_running.exchange(true)) return;
    m_streamFile = streamFile;
    if (m_streamFile.empty()) {
        wchar_t buf[1024];
        DWORD n = GetEnvironmentVariableW(L"VOLT_STREAM", buf, 1024);
        if (n > 0 && n < 1024) m_streamFile.assign(buf, n);
    }
    m_pipeThread = std::thread([this] { runPipe(); });
    if (!m_streamFile.empty())
        m_fileThread = std::thread([this] { runFile(); });
}

void Bridge::stop() {
    if (!m_running.exchange(false)) return;
    // Nudge the blocking ConnectNamedPipe by opening the pipe ourselves.
    HANDLE h = CreateFileW(L"\\\\.\\pipe\\VoltSpy", GENERIC_WRITE, 0, nullptr,
                           OPEN_EXISTING, 0, nullptr);
    if (h != INVALID_HANDLE_VALUE) CloseHandle(h);
    if (m_pipeThread.joinable()) m_pipeThread.join();
    if (m_fileThread.joinable()) m_fileThread.join();
}

void Bridge::emit(const std::string& line) {
    RemoteCall c = parseLine(line);
    {
        std::lock_guard<std::mutex> lk(m_mtx);
        m_queue.push_back(std::move(c));
    }
    m_total.fetch_add(1);
}

// Tail an append-only .jsonl file produced by Volt.lua's writefile/appendfile.
// Works with any executor that can write to its workspace folder.
void Bridge::runFile() {
    long long offset = 0;
    std::string acc;
    while (m_running.load()) {
        HANDLE f = CreateFileW(m_streamFile.c_str(), GENERIC_READ,
                               FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                               nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (f == INVALID_HANDLE_VALUE) { Sleep(300); continue; }

        LARGE_INTEGER size{};
        GetFileSizeEx(f, &size);
        // If the file shrank (game restarted / log rotated), re-read from start.
        if (size.QuadPart < offset) { offset = 0; acc.clear(); }

        LARGE_INTEGER seek; seek.QuadPart = offset;
        SetFilePointerEx(f, seek, nullptr, FILE_BEGIN);

        char buf[8192];
        DWORD got = 0;
        while (ReadFile(f, buf, sizeof(buf), &got, nullptr) && got) {
            acc.append(buf, got);
            offset += got;
            size_t nl;
            while ((nl = acc.find('\n')) != std::string::npos) {
                std::string ln = acc.substr(0, nl);
                acc.erase(0, nl + 1);
                if (!ln.empty() && ln.front() == '{') emit(ln);
            }
        }
        CloseHandle(f);
        m_connected.store(true);   // file present => treat as connected
        Sleep(120);
    }
}

void Bridge::runPipe() {
    while (m_running.load()) {
        HANDLE pipe = CreateNamedPipeW(
            L"\\\\.\\pipe\\VoltSpy",
            PIPE_ACCESS_INBOUND,
            PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
            1, 0, 1 << 16, 0, nullptr);
        if (pipe == INVALID_HANDLE_VALUE) {
            Sleep(250);
            continue;
        }

        BOOL ok = ConnectNamedPipe(pipe, nullptr)
                  ? TRUE : (GetLastError() == ERROR_PIPE_CONNECTED);
        if (!ok || !m_running.load()) {
            CloseHandle(pipe);
            continue;
        }
        m_connected.store(true);

        std::string acc;
        char buf[4096];
        DWORD got = 0;
        while (m_running.load() && ReadFile(pipe, buf, sizeof(buf), &got, nullptr) && got) {
            acc.append(buf, got);
            size_t nl;
            while ((nl = acc.find('\n')) != std::string::npos) {
                std::string line = acc.substr(0, nl);
                acc.erase(0, nl + 1);
                if (!line.empty()) emit(line);
            }
        }

        m_connected.store(false);
        DisconnectNamedPipe(pipe);
        CloseHandle(pipe);
    }
}

std::vector<RemoteCall> Bridge::drain() {
    std::vector<RemoteCall> out;
    std::lock_guard<std::mutex> lk(m_mtx);
    out.assign(m_queue.begin(), m_queue.end());
    m_queue.clear();
    return out;
}

} // namespace volt
