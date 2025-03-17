import React from "react";

export const metadata = {
  title: "My Next.js App",
  description: "A Next.js app using TypeScript",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
