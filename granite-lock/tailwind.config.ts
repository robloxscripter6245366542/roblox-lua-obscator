import type { Config } from 'tailwindcss';
const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        granite: { 950: '#080a09', 900: '#0b0f0d', 800: '#121815' },
        emerald: { glow: '#34d399', deep: '#059669', mint: '#6ee7b7' },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['ui-monospace', 'JetBrains Mono', 'SF Mono', 'Menlo', 'monospace'],
      },
      backdropBlur: { xs: '2px' },
      keyframes: {
        floaty: { '0%,100%': { transform: 'translateY(0)' }, '50%': { transform: 'translateY(-6px)' } },
      },
      animation: { floaty: 'floaty 6s ease-in-out infinite' },
    },
  },
  plugins: [],
};
export default config;
