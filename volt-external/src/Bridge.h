// Bridge.h — receives live capture data from the in-game Volt.lua.
//
// The external UI can't hook Roblox remotes itself (that lives inside the
// game process). Volt.lua keeps doing the __namecall hooking and streams
// each captured call out as one JSON line. This bridge ingests those lines
// over two transports, whichever the executor can do:
//
//   1) Named pipe  \\.\pipe\VoltSpy   — for executors with socket/pipe access.
//   2) File tail   VOLT_STREAM env / argv[1] — append-only .jsonl that any
//      executor can produce with writefile/appendfile. Most executors only
//      support this one, so it's the default path.
//
// Both transports feed the same queue. If nothing is connected the UI still
// runs with whatever is in the store (including seeded demo rows).
#pragma once

#include <windows.h>
#include <string>
#include <vector>
#include <deque>
#include <mutex>
#include <thread>
#include <atomic>

namespace volt {

enum class Dir { Out, In };

struct RemoteCall {
    Dir         dir = Dir::Out;
    std::wstring name;        // remote instance name
    std::wstring method;      // FireServer / InvokeServer / FireClient ...
    std::wstring rtype;       // RemoteEvent / RemoteFunction / ...
    std::wstring args;        // pretty-printed argument summary
    std::wstring source;      // caller script:line
    int         count = 1;    // merged-repeat counter
    bool        fromExec = false;
    double      t = 0;        // capture timestamp (game time)
};

class Bridge {
public:
    // `streamFile` is the .jsonl path to tail (empty => use VOLT_STREAM env).
    void start(const std::wstring& streamFile = L"");
    void stop();

    bool connected() const { return m_connected.load(); }
    uint64_t totalReceived() const { return m_total.load(); }

    // Drains everything received since the last call (thread-safe).
    std::vector<RemoteCall> drain();

private:
    void runPipe();           // named-pipe listener loop
    void runFile();           // file-tail listener loop
    void emit(const std::string& line);
    RemoteCall parseLine(const std::string& line);

    std::thread              m_pipeThread;
    std::thread              m_fileThread;
    std::atomic<bool>        m_running{false};
    std::atomic<bool>        m_connected{false};
    std::atomic<uint64_t>    m_total{0};
    std::mutex               m_mtx;
    std::deque<RemoteCall>   m_queue;
    std::wstring             m_streamFile;
};

} // namespace volt
