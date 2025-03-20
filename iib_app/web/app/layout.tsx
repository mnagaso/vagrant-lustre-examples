import React from "react";
import '../styles/globals.css';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'IIB HPC Cluster',
  description: 'Web interface for HPC cluster with Lustre and Slurm',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="h-full bg-gray-50">
      <body className="min-h-screen antialiased">
        <header className="bg-white shadow-sm">
          <nav className="max-w-7xl mx-auto px-4 py-3">
            <div className="flex justify-between items-center">
              <h1 className="text-xl font-bold text-gray-900">IIB HPC</h1>
              <div className="space-x-4">
                <a href="/" className="text-gray-600 hover:text-gray-900 transition-colors">
                  Home
                </a>
                <a href="/dashboard" className="text-gray-600 hover:text-gray-900 transition-colors">
                  Dashboard
                </a>
                <a href="/terminal" className="text-gray-600 hover:text-gray-900 transition-colors">
                  Terminal
                </a>
              </div>
            </div>
          </nav>
        </header>

        <main className="max-w-7xl mx-auto px-4 py-8">{children}</main>
      </body>
    </html>
  );
}
