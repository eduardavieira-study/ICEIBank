/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Poppins', 'sans-serif'],
        nunito: ['Nunito', 'sans-serif'],
      },
      colors: {
        puc: {
          dark: '#0A1D37',     // Dark blue
          blue: '#0F2B5C',     // PUC Minas main blue
          accent: '#1D4ED8',   // Accent blue
          light: '#F1F5F9',    // Slate background light
        }
      }
    },
  },
  plugins: [],
}
