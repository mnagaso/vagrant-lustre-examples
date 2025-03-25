'use client';

import { useState, FormEvent, useEffect, useRef } from 'react';
import Link from 'next/link';

interface LoginFormProps {
  onSuccess?: (token: string, message: string) => void;
  onError?: (message: string) => void;
  onLoadingChange?: (isLoading: boolean) => void;
}

export default function LoginForm({
  onSuccess,
  onError,
  onLoadingChange
}: LoginFormProps) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  // Create refs to access the actual DOM elements
  const usernameRef = useRef<HTMLInputElement>(null);
  const passwordRef = useRef<HTMLInputElement>(null);

  // Effect to detect browser autofill
  useEffect(() => {
    // Check for autofilled values when component mounts
    const checkAutofill = () => {
      // For username field
      if (usernameRef.current && usernameRef.current.value && usernameRef.current.value !== username) {
        setUsername(usernameRef.current.value);
      }

      // For password field
      if (passwordRef.current && passwordRef.current.value && passwordRef.current.value !== password) {
        setPassword(passwordRef.current.value);
      }
    };

    // Check immediately and then set up an interval to check periodically
    checkAutofill();

    // Some browsers delay autofill, so we check a few times
    const intervalId = setInterval(checkAutofill, 100);

    // Clean up interval after 1 second (should be enough for autofill)
    const timeoutId = setTimeout(() => {
      clearInterval(intervalId);
    }, 1000);

    return () => {
      clearInterval(intervalId);
      clearTimeout(timeoutId);
    };
  }, [username, password]);

  // Handler for when input values change manually or via events
  const handleInputChange = (field: 'username' | 'password', value: string) => {
    if (field === 'username') {
      setUsername(value);
    } else {
      setPassword(value);
    }
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    // Basic validation
    if (!username || !password) {
      const errorMsg = 'Username and password are required';
      setError(errorMsg);
      if (onError) onError(errorMsg);
      return;
    }

    setIsLoading(true);
    if (onLoadingChange) onLoadingChange(true);
    setError('');

    try {
      // For demo purposes - simulate API call
      // In production, replace with actual API call
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Simulate successful login
      if (username === 'admin' && password === 'admin') {
        const token = 'demo-token-' + Math.random().toString(36).substring(2);
        if (onSuccess) {
          onSuccess(token, 'Login successful');
        }
      } else {
        throw new Error('Invalid credentials');
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Login failed';
      setError(errorMsg);
      if (onError) onError(errorMsg);
    } finally {
      setIsLoading(false);
      if (onLoadingChange) onLoadingChange(false);
    }
  };

  return (
    <div className="w-full max-w-sm bg-white rounded-md border border-gray-200 p-5">
      <h2 className="text-lg font-medium text-gray-900 mb-4">Sign in</h2>

      {error && (
        <div className="mb-4 text-sm text-gray-800 p-2 bg-gray-100 rounded-sm" role="alert">
          {error}
        </div>
      )}

      <form className="space-y-4" onSubmit={handleSubmit}>
        <div>
          <input
            id="username"
            name="username"
            type="text"
            autoComplete="username"
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-sm text-sm focus:outline-none focus:ring-1 focus:ring-black"
            placeholder="Username"
            value={username}
            onChange={(e) => handleInputChange('username', e.target.value)}
            onInput={(e) => handleInputChange('username', e.currentTarget.value)}
            ref={usernameRef}
            disabled={isLoading}
          />
        </div>

        <div>
          <input
            id="password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-sm text-sm focus:outline-none focus:ring-1 focus:ring-black"
            placeholder="Password"
            value={password}
            onChange={(e) => handleInputChange('password', e.target.value)}
            onInput={(e) => handleInputChange('password', e.currentTarget.value)}
            ref={passwordRef}
            disabled={isLoading}
          />
        </div>

        <div className="flex justify-end">
          <Link href="/forgot-password" className="text-xs text-gray-600 hover:text-black">
            Forgot password?
          </Link>
        </div>

        <button
          type="submit"
          disabled={isLoading}
          className="w-full bg-black text-white py-2 px-4 rounded-sm text-sm font-medium hover:bg-gray-800 focus:outline-none focus:ring-1 focus:ring-black focus:ring-offset-1 disabled:opacity-50"
        >
          {isLoading ? (
            <span className="flex items-center justify-center">
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Signing in...
            </span>
          ) : 'Sign in'}
        </button>
      </form>
    </div>
  );
}
