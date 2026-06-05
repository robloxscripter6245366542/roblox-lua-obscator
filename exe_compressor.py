#!/usr/bin/env python3
"""
EXE Compressor — Drag & Drop
Supports two modes:
  UPX Mode  : fast, ~40-60% smaller, decompresses transparently at launch
  LZMA Mode : max compression, ~75-90% smaller, self-extracts to temp and runs
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import subprocess, os, sys, threading, urllib.request, zipfile, lzma
import shutil, struct, tempfile, time
from pathlib import Path

APP_DIR   = Path(sys.executable).parent if getattr(sys, "frozen", False) else Path(__file__).parent
UPX_DIR   = APP_DIR / "_upx"
UPX_EXE   = UPX_DIR / "upx.exe"
UPX_URL   = "https://github.com/upx/upx/releases/download/v4.2.4/upx-4.2.4-win64.zip"

# ─── Self-extract stub source ──────────────────────────────────────────────────
# This small Python script is embedded in every LZMA-compressed output.
# PyInstaller (--onefile) packs it + lzma payload into the final exe.
STUB_SOURCE = r'''
import lzma, os, sys, subprocess, tempfile, atexit, struct

def main():
    exe_path = sys.executable if getattr(sys,"frozen",False) else __file__
    with open(exe_path,"rb") as f:
        data = f.read()
    # Find magic marker
    MAGIC = b"\x00CLYDE_LZMA\x00"
    idx = data.rfind(MAGIC)
    if idx == -1:
        print("Payload not found"); sys.exit(1)
    offset = idx + len(MAGIC)
    size = struct.unpack_from("<Q", data, offset)[0]
    compressed = data[offset+8 : offset+8+size]
    raw = lzma.decompress(compressed)
    tmp = tempfile.mkdtemp(prefix="clydeex_")
    out_exe = os.path.join(tmp, "app.exe")
    atexit.register(lambda: shutil.rmtree(tmp, ignore_errors=True))
    with open(out_exe,"wb") as f:
        f.write(raw)
    result = subprocess.run([out_exe] + sys.argv[1:])
    sys.exit(result.returncode)

if __name__ == "__main__":
    import shutil
    main()
'''

MAGIC_MARKER = b"\x00CLYDE_LZMA\x00"

# ─── Helpers ──────────────────────────────────────────────────────────────────
def human(n):
    for unit in ("B","KB","MB","GB"):
        if n < 1024: return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} TB"

def pct(orig, comp):
    return f"{100*(1-comp/orig):.1f}% smaller"

# ─── UPX downloader ───────────────────────────────────────────────────────────
def ensure_upx(log):
    if UPX_EXE.exists(): return True
    log("Downloading UPX 4.2.4…")
    UPX_DIR.mkdir(parents=True, exist_ok=True)
    zip_path = UPX_DIR / "upx.zip"
    try:
        urllib.request.urlretrieve(UPX_URL, zip_path,
            reporthook=lambda *_: None)
        with zipfile.ZipFile(zip_path) as z:
            for name in z.namelist():
                if name.endswith("upx.exe"):
                    with z.open(name) as src, open(UPX_EXE,"wb") as dst:
                        shutil.copyfileobj(src, dst)
                    break
        zip_path.unlink(missing_ok=True)
        log("UPX downloaded.")
        return True
    except Exception as e:
        log(f"UPX download failed: {e}")
        return False

# ─── Compression logic ────────────────────────────────────────────────────────
def compress_upx(src: Path, dst: Path, level: int, log):
    shutil.copy2(src, dst)
    flag = f"-{level}"
    cmd  = [str(UPX_EXE), flag, "--no-color", str(dst)]
    log(f"Running UPX {flag}…")
    proc = subprocess.run(cmd, capture_output=True, text=True)
    out  = (proc.stdout + proc.stderr).strip()
    for line in out.splitlines():
        if line.strip(): log(line)
    if proc.returncode not in (0, 1):
        raise RuntimeError(f"UPX failed (code {proc.returncode})")

def compress_lzma(src: Path, dst: Path, log):
    log("Reading source…")
    raw = src.read_bytes()
    log(f"Compressing {human(len(raw))} with LZMA (preset=9, extreme)…")
    t0 = time.time()
    compressed = lzma.compress(raw,
        format=lzma.FORMAT_XZ,
        filters=[{"id": lzma.FILTER_LZMA2, "preset": 9 | lzma.PRESET_EXTREME}])
    dt = time.time() - t0
    log(f"LZMA done in {dt:.1f}s  →  {human(len(compressed))}")

    # Build self-extracting stub using the bundled Python approach:
    # We append the LZMA payload after a compiled minimal stub exe.
    # If PyInstaller is available we compile; otherwise we create a .bat launcher
    # that extracts + runs via Python. Fallback: write raw LZMA + a companion
    # extractor script so the user can still run it.

    # Try PyInstaller compilation
    stub_py = dst.parent / "_stub_tmp.py"
    stub_py.write_text(STUB_SOURCE, encoding="utf-8")

    pyinst = shutil.which("pyinstaller") or shutil.which("pyinstaller3")
    compiled = False
    if pyinst:
        log("Compiling self-extractor stub with PyInstaller…")
        build_dir = dst.parent / "_pyi_build"
        cmd = [
            sys.executable, "-m", "PyInstaller",
            "--onefile", "--noconsole",
            "--distpath", str(dst.parent),
            "--workpath", str(build_dir),
            "--specpath", str(build_dir),
            "--name", dst.stem,
            str(stub_py),
        ]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode == 0 and dst.exists():
            compiled = True
            shutil.rmtree(build_dir, ignore_errors=True)
            (dst.parent / f"{dst.stem}.spec").unlink(missing_ok=True)
            log("Stub compiled.")
        else:
            log("PyInstaller compile failed — using .bat launcher fallback.")

    if not compiled:
        # Fallback: write a .bat that calls python to extract + run
        bat_path = dst.with_suffix(".bat")
        bat_path.write_text(
            f'@echo off\n'
            f'python "{dst.stem}_extract.py" %*\n',
            encoding="utf-8")
        # Write the extractor helper
        ext_py = dst.parent / f"{dst.stem}_extract.py"
        ext_py.write_text(STUB_SOURCE, encoding="utf-8")
        # Write the compressed payload as the "exe" file
        dst.write_bytes(compressed)
        log(f"⚠ No PyInstaller — wrote {dst.stem}_extract.py + {dst.stem}.bat instead.")
        log("  Run the .bat to launch. Or install PyInstaller and re-compress.")
        stub_py.unlink(missing_ok=True)
        return

    stub_py.unlink(missing_ok=True)

    # Append payload to compiled stub
    log("Appending payload to stub…")
    with open(dst, "ab") as f:
        f.write(MAGIC_MARKER)
        f.write(struct.pack("<Q", len(compressed)))
        f.write(compressed)
    log("Self-extractor built.")

# ─── Main worker ──────────────────────────────────────────────────────────────
def run_compression(src_path, mode, upx_level, out_dir, log, done_cb):
    try:
        src  = Path(src_path)
        if not src.exists():
            log("File not found!"); done_cb(False); return

        stem = src.stem
        dst  = (Path(out_dir) if out_dir else src.parent) / f"{stem}_compressed.exe"
        log(f"Source : {src.name}  ({human(src.stat().st_size)})")
        log(f"Output : {dst.name}")
        log(f"Mode   : {mode.upper()}")
        log("─" * 46)

        if mode == "upx":
            if not ensure_upx(log):
                done_cb(False); return
            compress_upx(src, dst, upx_level, log)
        else:
            compress_lzma(src, dst, log)

        orig_sz = src.stat().st_size
        comp_sz = dst.stat().st_size
        log("─" * 46)
        log(f"✓ Done!  {human(orig_sz)} → {human(comp_sz)}  ({pct(orig_sz, comp_sz)})")
        log(f"Saved to: {dst}")
        done_cb(True)
    except Exception as e:
        log(f"✗ Error: {e}")
        done_cb(False)

# ─── GUI ──────────────────────────────────────────────────────────────────────
class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("EXE Compressor")
        self.resizable(False, False)
        self.configure(bg="#0d0d12")
        self._build_ui()
        self._setup_dnd()
        self._file = ""

    def _build_ui(self):
        PAD = {"padx": 12, "pady": 6}

        # Drop zone
        self.drop_frame = tk.Frame(self, bg="#1a1a2e", width=420, height=110,
                                   highlightbackground="#6e3cff",
                                   highlightthickness=2, cursor="hand2")
        self.drop_frame.pack(padx=16, pady=(16, 6))
        self.drop_frame.pack_propagate(False)

        self.drop_lbl = tk.Label(self.drop_frame,
            text="⬇  Drag & Drop your EXE here\nor click to browse",
            bg="#1a1a2e", fg="#a0a8d0",
            font=("Segoe UI", 11), justify="center", cursor="hand2")
        self.drop_lbl.place(relx=0.5, rely=0.5, anchor="center")
        self.drop_frame.bind("<Button-1>", self._browse)
        self.drop_lbl.bind("<Button-1>", self._browse)

        # File label
        self.file_lbl = tk.Label(self, text="No file selected",
            bg="#0d0d12", fg="#606880", font=("Segoe UI", 9))
        self.file_lbl.pack(PAD["padx"], pady=2)

        # Mode selection
        mode_row = tk.Frame(self, bg="#0d0d12")
        mode_row.pack(padx=12, pady=4, fill="x")
        tk.Label(mode_row, text="Mode:", bg="#0d0d12", fg="#c0c8e0",
                 font=("Segoe UI", 10)).pack(side="left")
        self.mode_var = tk.StringVar(value="lzma")
        for val, lbl in [("upx", "UPX  (fast, 40-60%)"), ("lzma", "LZMA  (max, 75-90%)")]:
            tk.Radiobutton(mode_row, text=lbl, variable=self.mode_var, value=val,
                bg="#0d0d12", fg="#c0c8e0", selectcolor="#1a1a2e",
                activebackground="#0d0d12", activeforeground="#ffffff",
                font=("Segoe UI", 10)).pack(side="left", padx=8)

        # UPX level (only visible in UPX mode)
        upx_row = tk.Frame(self, bg="#0d0d12")
        upx_row.pack(padx=12, pady=2, fill="x")
        tk.Label(upx_row, text="UPX level:", bg="#0d0d12", fg="#c0c8e0",
                 font=("Segoe UI", 9)).pack(side="left")
        self.upx_level = tk.IntVar(value=9)
        self.upx_spin = tk.Spinbox(upx_row, from_=1, to=9, width=3,
            textvariable=self.upx_level, bg="#1a1a2e", fg="#c0c8e0",
            buttonbackground="#1a1a2e", font=("Segoe UI", 9),
            state="readonly")
        self.upx_spin.pack(side="left", padx=4)
        tk.Label(upx_row, text="(9 = smallest)", bg="#0d0d12", fg="#606880",
                 font=("Segoe UI", 8)).pack(side="left")

        # Output dir
        out_row = tk.Frame(self, bg="#0d0d12")
        out_row.pack(padx=12, pady=2, fill="x")
        tk.Label(out_row, text="Output:", bg="#0d0d12", fg="#c0c8e0",
                 font=("Segoe UI", 9)).pack(side="left")
        self.out_var = tk.StringVar(value="Same folder as source")
        out_entry = tk.Entry(out_row, textvariable=self.out_var, width=32,
            bg="#1a1a2e", fg="#a0a8d0", insertbackground="#a0a8d0",
            font=("Segoe UI", 9), relief="flat")
        out_entry.pack(side="left", padx=4)
        tk.Button(out_row, text="Browse", bg="#2a2a3e", fg="#a0a8d0",
            font=("Segoe UI", 8), relief="flat", cursor="hand2",
            command=self._browse_out).pack(side="left")

        # Compress button
        self.go_btn = tk.Button(self, text="▶  Compress",
            bg="#6e3cff", fg="white", font=("Segoe UI Semibold", 11),
            relief="flat", cursor="hand2", pady=6,
            command=self._start)
        self.go_btn.pack(padx=12, pady=8, fill="x")

        # Progress bar
        style = ttk.Style()
        style.theme_use("default")
        style.configure("C.Horizontal.TProgressbar",
            troughcolor="#1a1a2e", background="#6e3cff", bordercolor="#0d0d12")
        self.progress = ttk.Progressbar(self, style="C.Horizontal.TProgressbar",
            mode="indeterminate", length=420)
        self.progress.pack(padx=12, pady=(0, 4), fill="x")

        # Log area
        log_frame = tk.Frame(self, bg="#0d0d12")
        log_frame.pack(padx=12, pady=(0, 12), fill="both", expand=True)
        self.log_text = tk.Text(log_frame, height=10, bg="#0d0f18", fg="#7af0a0",
            font=("Consolas", 9), relief="flat", state="disabled",
            insertbackground="#7af0a0", selectbackground="#2a3a4a")
        sb = tk.Scrollbar(log_frame, command=self.log_text.yview, bg="#1a1a2e")
        self.log_text.configure(yscrollcommand=sb.set)
        sb.pack(side="right", fill="y")
        self.log_text.pack(side="left", fill="both", expand=True)

    def _setup_dnd(self):
        try:
            from tkinterdnd2 import DND_FILES, TkinterDnD
            # If tkinterdnd2 is available, re-init as TkinterDnD window
            # (requires running as TkinterDnD.Tk(); handled at __main__)
        except ImportError:
            pass
        # Bind drop events if available
        try:
            self.drop_frame.drop_target_register("DND_Files")
            self.drop_frame.dnd_bind("<<Drop>>", self._on_drop)
            self.drop_lbl.drop_target_register("DND_Files")
            self.drop_lbl.dnd_bind("<<Drop>>", self._on_drop)
        except Exception:
            pass

    def _on_drop(self, event):
        path = event.data.strip().strip("{}")
        self._set_file(path)

    def _browse(self, _event=None):
        path = filedialog.askopenfilename(
            title="Select EXE to compress",
            filetypes=[("Executable", "*.exe"), ("All files", "*.*")])
        if path: self._set_file(path)

    def _browse_out(self):
        d = filedialog.askdirectory(title="Select output folder")
        if d: self.out_var.set(d)

    def _set_file(self, path):
        self._file = path
        name = Path(path).name
        try:
            sz = human(Path(path).stat().st_size)
            self.file_lbl.config(text=f"📄  {name}  ({sz})", fg="#c0c8e0")
        except Exception:
            self.file_lbl.config(text=f"📄  {name}", fg="#c0c8e0")
        self.drop_lbl.config(text=f"✓  {name}")
        self.drop_frame.config(highlightbackground="#3cff8f")

    def log(self, msg):
        def _do():
            self.log_text.config(state="normal")
            self.log_text.insert("end", msg + "\n")
            self.log_text.see("end")
            self.log_text.config(state="disabled")
        self.after(0, _do)

    def _start(self):
        if not self._file:
            messagebox.showwarning("No file", "Drag an EXE or click Browse first.")
            return
        mode      = self.mode_var.get()
        upx_level = self.upx_level.get()
        out_dir   = self.out_var.get()
        if out_dir == "Same folder as source": out_dir = ""

        self.go_btn.config(state="disabled")
        self.progress.start(12)
        self.log_text.config(state="normal"); self.log_text.delete("1.0","end"); self.log_text.config(state="disabled")

        def done(ok):
            self.after(0, lambda: self.progress.stop())
            self.after(0, lambda: self.go_btn.config(state="normal"))
            if ok:
                self.after(0, lambda: messagebox.showinfo("Done", "Compression complete!\nCheck the log for details."))

        threading.Thread(target=run_compression,
            args=(self._file, mode, upx_level, out_dir, self.log, done),
            daemon=True).start()


# ─── Entry point ──────────────────────────────────────────────────────────────
def main():
    # Try to use tkinterdnd2 for native drag-and-drop
    try:
        from tkinterdnd2 import TkinterDnD
        root = TkinterDnD.Tk()
        # Re-use our App class but swap the root
        root.title("EXE Compressor")
        root.resizable(False, False)
        root.configure(bg="#0d0d12")
        app = App.__new__(App)
        tk.Tk.__init__(app)
        app.destroy()  # destroy the tk.Tk() we accidentally made
        # Actually just init normally — tkinterdnd2 monkeypatches Tk
        app = App()
        app.mainloop()
    except ImportError:
        app = App()
        app.mainloop()


if __name__ == "__main__":
    main()
