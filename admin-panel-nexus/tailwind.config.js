/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx}",
  ],
  theme: {
    extend: {
      colors: {
        nexus: {
          bg: '#090909',
          card: '#151515',
          primary: '#6D28FF',
          secondary: '#2B7FFF',
          success: '#16A34A',
          warning: '#F59E0B',
          error: '#DC2626',
          text: '#FFFFFF',
          'text-secondary': '#A1A1AA',
        }
      },
      backdropBlur: {
        glass: '10px'
      },
      backgroundColor: {
        glass: 'rgba(255, 255, 255, 0.1)'
      },
      borderColor: {
        glass: 'rgba(255, 255, 255, 0.2)'
      }
    },
  },
  plugins: [],
}
