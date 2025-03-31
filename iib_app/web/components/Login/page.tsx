'use client';

import { useState, FormEvent, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from './useAuth';
import { useFormInputs } from './useFormInputs';

interface LoginFormProps {
  onSuccess?: (token: string, message: string) => void;
  onLoadingChange?: (isLoading: boolean) => void;
}

export default function LoginForm({
  onSuccess,
  onLoadingChange
}: LoginFormProps) {
  const {
    inputs,
    handleInputChange,
    inputRefs
  } = useFormInputs(['username', 'password']);

  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { login, detectRateLimit, formatErrorMessage } = useAuth();

  // Handle autofill detection
  useEffect(() => {
    const checkAutofill = () => {
      Object.entries(inputRefs.current).forEach(([field, ref]) => {
        if (ref && ref.value && ref.value !== inputs[field]) {
          handleInputChange(field as 'username' | 'password', ref.value);
        }
      });
    };

    checkAutofill();
    const intervalId = setInterval(checkAutofill, 100);
    const timeoutId = setTimeout(() => {
      clearInterval(intervalId);
    }, 1000);

    return () => {
      clearInterval(intervalId);
      clearTimeout(timeoutId);
    };
  }, [inputs, handleInputChange, inputRefs]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    if (!inputs.username || !inputs.password) {
      setError('Username and password are required');
      return;
    }

    setIsLoading(true);
    if (onLoadingChange) onLoadingChange(true);
    setError('');

    try {
      const result = await login(inputs.username, inputs.password);

      if (!result.success) {
        const { response, data } = result;
        // Add null checks for both response and data
        let errorDetails = 'Unknown error';

        if (response && data) {
          errorDetails = `Status: ${response.status}, Message: ${data.error || 'No error message'}`;
          console.error(`Authentication failed: ${errorDetails}`);

          // Handle error cases
          let errorMsg = data.error || 'Authentication failed';
          errorMsg = `${errorMsg} (${errorDetails})`;

          const isRateLimited = detectRateLimit(response, errorMsg);
          errorMsg = formatErrorMessage(response, errorMsg, isRateLimited);

          setError(errorMsg);
        } else {
          setError('Authentication failed - server unreachable');
        }
        return;
      }

      const { data } = result;

      if (data?.requirePasswordChange) {
        const msg = 'You need to change your password before continuing';
        setError(msg);

        setTimeout(() => {
          window.location.href = `/change-password?userId=${data.userId}`;
        }, 2000);
        return;
      }

      if (onSuccess && data) {
        const token = data.token || 'auth-token';
        onSuccess(token, data.message || 'Login successful');
      }

      setError('');

    } catch (err) {
      console.error('Login request failed completely:', err);
      const errorMsg = err instanceof Error ? err.message : 'Login failed';
      setError(`${errorMsg} (Network error)`);
    } finally {
      setIsLoading(false);
      if (onLoadingChange) onLoadingChange(false);
    }
  };

  return (
    <div className="w-full max-w-sm bg-white rounded-md border border-gray-200 p-5">
      <h2 className="text-lg font-medium text-gray-900 mb-4">Sign in</h2>

      {error && (
        <div className="mb-4 text-sm text-red-800 p-3 bg-red-50 border border-red-200 rounded-sm" role="alert">
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
            className="w-full px-3 py-2 border border-gray-300 rounded-sm text-sm focus:outline-none focus:ring-1 focus:ring-black bg-white text-gray-900"
            placeholder="Username"
            value={inputs.username}
            onChange={(e) => handleInputChange('username', e.target.value)}
            onInput={(e) => handleInputChange('username', e.currentTarget.value)}
            ref={(el) => { inputRefs.current.username = el; }}
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
            className="w-full px-3 py-2 border border-gray-300 rounded-sm text-sm focus:outline-none focus:ring-1 focus:ring-black bg-white text-gray-900"
            placeholder="Password"
            value={inputs.password}
            onChange={(e) => handleInputChange('password', e.target.value)}
            onInput={(e) => handleInputChange('password', e.currentTarget.value)}
            ref={(el) => { inputRefs.current.password = el; }}
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
