import type { Metadata, Viewport } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Granite Lock — Lua / Luau Obfuscator',
  description:
    'Granite Lock — premium client-side Lua & Roblox Luau obfuscator with a custom bytecode VM. Runs entirely in your browser; your code never leaves the page.',
  icons: {
    icon:
      "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Crect x='3' y='11' width='18' height='11' rx='3' fill='%2310b981'/%3E%3Cpath d='M7 11V7a5 5 0 0 1 10 0v4' fill='none' stroke='%2334d399' stroke-width='2'/%3E%3C/svg%3E",
  },
};

export const viewport: Viewport = {
  themeColor: '#080a09',
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
