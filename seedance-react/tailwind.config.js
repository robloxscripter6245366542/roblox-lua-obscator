/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        bg: '#08090d',
        surface: '#10121a',
        surface2: '#161925',
        border: 'rgba(255,255,255,0.07)',
        accent: '#7C3AED',
        accent2: '#2563EB',
        muted: '#8b8fa8',
        dim: '#555872',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      animation: {
        'pulse-slow': 'pulse 2s ease-in-out infinite',
        'spin-slow': 'spin 1.2s linear infinite',
        'slide-up': 'slideUp 0.25s ease',
        'fade-in': 'fadeIn 0.3s ease',
        'shimmer': 'shimmer 2s infinite linear',
      },
      keyframes: {
        slideUp: {
          from: { opacity: 0, transform: 'translateY(12px)' },
          to: { opacity: 1, transform: 'translateY(0)' },
        },
        fadeIn: {
          from: { opacity: 0 },
          to: { opacity: 1 },
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
      },
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'shimmer-gradient': 'linear-gradient(90deg, transparent 0%, rgba(255,255,255,0.05) 50%, transparent 100%)',
      },
    },
  },
  plugins: [],
}
