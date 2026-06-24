/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        v: '#7c3aed',
        c: '#06b6d4',
        g: '#10b981',
        p: '#ec4899',
        o: '#f59e0b',
      },
      fontFamily: {
        mono: ["'SF Mono'", "'Fira Code'", 'monospace'],
      },
    },
  },
  plugins: [],
}
