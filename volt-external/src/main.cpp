// main.cpp — entry point for the Volt external UI.
#include "App.h"

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int) {
    volt::App app;
    if (!app.init(hInstance))
        return 1;
    return app.run();
}
