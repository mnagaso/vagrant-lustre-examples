"use client";

import Image from "next/image";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

export default function Toppage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Clear messages when component mounts
  useEffect(() => {
    setError(null);
    setSuccess(null);
  }, []);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setIsLoading(true);

    const formData = new FormData(e.currentTarget);
    const username = formData.get("username") as string;
    const password = formData.get("password") as string;

    try {
      const res = await fetch("/api/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });

      const data = await res.json();

      if (res.ok) {
        if (data.token) {
          localStorage.setItem("authToken", data.token);
          setSuccess(data.message || "Login successful");
          // Use Next.js router for navigation after successful login
          setTimeout(() => router.push("/dashboard"), 1000);
        }
      } else {
        setError(data.error || 'Login failed');
        console.error('Login response:', res.status, data);
      }
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'An unexpected error occurred';
      setError(`An error occurred: ${errorMessage}`);
      console.error('Login error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="grid grid-rows-[20px_1fr_20px] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20 font-[family-name:var(--font-geist-sans)]">
      <main className="flex flex-col gap-[32px] row-start-2 items-center sm:items-start">
        <h1 className="text-2xl font-bold">IIB-GPU-Cluster</h1>
        <Image
          className="dark:invert"
          src="/models3.svg"
          alt="WMT-AGIS logo"
          width={180}
          height={38}
          priority
        />
        <ol className="list-inside list-decimal text-sm/6 text-center sm:text-left font-[family-name:var(--font-geist-mono)]">
          <li className="mb-2 tracking-[-.01em]">
            Create your account by asking your administrator for an invite.
          </li>
          <li className="tracking-[-.01em]">
            Login with your username and password.
          </li>
        </ol>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
            {error}
          </div>
        )}

        {success && (
          <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded">
            {success}
          </div>
        )}

        <form className="flex flex-col gap-4 bg-black text-white p-4 w-full max-w-md" onSubmit={handleSubmit}>
          <div className="mb-2">
            <label className="font-semibold block mb-1" htmlFor="username">Username:</label>
            <input
              type="text"
              id="username"
              name="username"
              className="border p-2 bg-black text-white placeholder-white w-full"
              placeholder="Enter your username (try 'admin')"
              required
              disabled={isLoading}
            />
          </div>

          <div className="mb-4">
            <label className="font-semibold block mb-1" htmlFor="password">Password:</label>
            <input
              type="password"
              id="password"
              name="password"
              className="border p-2 bg-black text-white placeholder-white w-full"
              placeholder="Enter your password (try 'admin')"
              required
              disabled={isLoading}
            />
          </div>

          <button
            type="submit"
            className="rounded bg-white text-black px-4 py-2 hover:bg-gray-200 transition-colors disabled:opacity-50"
            disabled={isLoading}
          >
            {isLoading ? 'Logging in...' : 'Login'}
          </button>
        </form>
      </main>
    </div>
  );
}
