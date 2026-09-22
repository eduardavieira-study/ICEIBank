/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        display: ['Sora', 'sans-serif'],
        // Uso pontual: título de destaque da hero na landing page.
        poppins: ['Poppins', 'sans-serif'],
      },
      colors: {
        // Marca — roxo (primária)
        primary: {
          50: '#F5F1FE',
          100: '#EBE2FD',
          200: '#D3C0FA',
          300: '#B695F6',
          400: '#9B6EF3',
          500: '#8146EE',
          600: '#6D28D9',
          700: '#5B1EB8',
          800: '#481894',
          900: '#37136F',
          950: '#220A47',
        },
        // Marca — rosa (secundária / detalhes)
        secondary: {
          50: '#FEF1F8',
          100: '#FDE3F1',
          200: '#FBC6E3',
          300: '#F894CB',
          400: '#F45FAF',
          500: '#EC4899',
          600: '#D42E7D',
          700: '#B01E64',
          800: '#8F1B53',
          900: '#771A48',
        },
        // Cor complementar — verde-água
        accent: {
          50: '#EDFDFA',
          100: '#D2FAF3',
          200: '#A9F2E6',
          300: '#71E4D4',
          400: '#3ECEBE',
          500: '#22B2A3',
          600: '#178F85',
          700: '#17726C',
          800: '#185B57',
          900: '#184B49',
        },
        surface: {
          light: '#FFFFFF',
          'light-alt': '#F3EFFB',
          dark: '#15101F',
          'dark-alt': '#1D1729',
        },
      },
      backgroundImage: {
        // Uso pontual: apenas no ícone da marca e em pequenos detalhes — não em botões ou blocos grandes.
        'brand-gradient': 'linear-gradient(135deg, #6D28D9 0%, #C0389B 100%)',
      },
    },
  },
  plugins: [],
}
