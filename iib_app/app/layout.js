import './globals.css';

export const metadata = {
  title: 'IIB Inference App',
  description: 'Inference Application for IIB GPU Cluster'
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
