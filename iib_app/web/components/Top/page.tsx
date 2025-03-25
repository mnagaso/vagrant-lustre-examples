"use client";

import Image from "next/image";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import LoginPage from '@/components/Login/page';

export default function Toppage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  // Check if user is already logged in
  useEffect(() => {
    // In a real app, check local storage or cookies for authentication token
    const savedToken = localStorage.getItem('authToken');
    if (savedToken) {
      setIsLoggedIn(true);
    }
  }, []);

  const handleLoginSuccess = (token: string, message: string) => {
    // Save token to localStorage in a real application
    localStorage.setItem('authToken', token);

    setSuccess(message || "Login successful");
    setIsLoggedIn(true);

    // Navigate to dashboard in a real application
    // setTimeout(() => router.push("/dashboard"), 1000);
  };

  const handleLoginError = (errorMessage: string) => {
    setError(errorMessage);
  };

  const handleLoadingChange = (loading: boolean) => {
    setIsLoading(loading);
  };

  const handleLogout = () => {
    localStorage.removeItem('authToken');
    setIsLoggedIn(false);
    setSuccess(null);
    setError(null);
  };

  return (
    <div className="min-h-screen p-6 flex flex-col items-center justify-center bg-white">
      <div className="max-w-md w-full space-y-6">
        <div className="text-center">
          <h1 className="text-2xl font-medium mb-3">IIB Cluster Interface</h1>
          <Image
            src="/models3.svg"
            alt="WMT-AGIS logo"
            width={120}
            height={30}
            priority
            className="mx-auto mb-6 dark:invert grayscale hover:grayscale-0 transition-all duration-300"
          />
        </div>

        {error && (
          <div className="border border-gray-200 text-gray-700 px-4 py-3 rounded-sm text-sm">
            {error}
          </div>
        )}

        {success && (
          <div className="border border-gray-200 text-gray-700 px-4 py-3 rounded-sm text-sm">
            {success}
          </div>
        )}

        {isLoggedIn ? (
          <div className="bg-white border border-gray-200 rounded-sm p-5 text-center">
            <h2 className="text-lg font-medium text-gray-900 mb-4">Welcome to IIB Cluster Interface</h2>
            <p className="text-gray-600 mb-6">You are successfully logged in</p>

            <div className="flex flex-col space-y-3">
              <button
                onClick={() => router.push('/dashboard')}
                className="bg-black text-white py-2 px-4 rounded-sm text-sm font-medium hover:bg-gray-800 focus:outline-none focus:ring-1 focus:ring-black"
              >
                Go to Dashboard
              </button>

              <button
                onClick={handleLogout}
                className="bg-white text-gray-700 py-2 px-4 border border-gray-300 rounded-sm text-sm font-medium hover:bg-gray-100 focus:outline-none focus:ring-1 focus:ring-black"
              >
                Sign Out
              </button>
            </div>
          </div>
        ) : (
          <>
            <div className="text-sm text-gray-600 mb-4">
              <p className="text-center">Please log in with your credentials</p>
            </div>

            <LoginPage
              onSuccess={handleLoginSuccess}
              onError={handleLoginError}
              onLoadingChange={handleLoadingChange}
            />

            {isLoading && (
              <div className="text-center text-gray-500 text-sm mt-3">
                <div className="inline-block h-3 w-3 animate-spin rounded-full border border-solid border-current border-r-transparent mr-1 align-[-0.125em]"></div>
                Processing...
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
