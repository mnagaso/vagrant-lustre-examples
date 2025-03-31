'use client';

import { Suspense } from 'react';
import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';

// Separate component that uses useSearchParams
function ResetPasswordContent() {
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isTokenValid, setIsTokenValid] = useState<boolean | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState<{type: 'success' | 'error', text: string} | null>(null);

  const router = useRouter();
  const searchParams = useSearchParams();
  const token = searchParams.get('token');

  useEffect(() => {
    // Verify token when component mounts
    const verifyToken = async () => {
      if (!token) {
        setIsTokenValid(false);
        setMessage({
          type: 'error',
          text: 'Invalid or missing reset token.'
        });
        return;
      }

      try {
        const response = await fetch(`/api/auth/verify-token?token=${token}`);
        const data = await response.json();

        if (response.ok) {
          setIsTokenValid(true);
        } else {
          setIsTokenValid(false);
          setMessage({
            type: 'error',
            text: data.error || 'Invalid or expired token. Please request a new password reset.'
          });
        }
      } catch {
        setIsTokenValid(false);
        setMessage({
          type: 'error',
          text: 'An error occurred while verifying your token. Please try again.'
        });
      }
    };

    verifyToken();
  }, [token]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Form validation
    if (newPassword !== confirmPassword) {
      setMessage({
        type: 'error',
        text: 'Passwords do not match.'
      });
      return;
    }

    if (newPassword.length < 10) {
      setMessage({
        type: 'error',
        text: 'Password must be at least 10 characters long.'
      });
      return;
    }

    setIsSubmitting(true);
    setMessage(null);

    try {
      const response = await fetch('/api/auth/reset-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token, newPassword }),
      });

      const data = await response.json();

      if (response.ok) {
        setMessage({
          type: 'success',
          text: 'Your password has been reset successfully. You will be redirected to the login page.'
        });

        // Redirect to login page after 3 seconds
        setTimeout(() => router.push('/'), 3000);
      } else {
        setMessage({
          type: 'error',
          text: data.error || 'Failed to reset password. Please try again.'
        });
      }
    } catch {
      setMessage({
        type: 'error',
        text: 'An error occurred while resetting your password. Please try again.'
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isTokenValid === null) {
    // Loading state
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="w-full max-w-md p-8 space-y-8 bg-white rounded-xl shadow-md">
          <p className="text-center text-gray-600">Verifying your reset token...</p>
        </div>
      </div>
    );
  }

  if (isTokenValid === false) {
    // Invalid token
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="w-full max-w-md p-8 space-y-8 bg-white rounded-xl shadow-md">
          <div className="text-center">
            <h1 className="text-3xl font-bold text-gray-900">Invalid Token</h1>
            <p className="mt-2 text-sm text-gray-600">
              {message?.text || 'Your password reset token is invalid or has expired.'}
            </p>
          </div>
          <div className="text-center">
            <Link
              href="/forgot-password"
              className="text-blue-600 hover:text-blue-500 font-medium"
            >
              Request a new password reset
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="w-full max-w-md p-8 space-y-8 bg-white rounded-xl shadow-md">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900">Reset Your Password</h1>
          <p className="mt-2 text-sm text-gray-600">
            Please enter a new secure password for your account
          </p>
        </div>

        {message && (
          <div
            className={`p-4 rounded-md ${
              message.type === 'success' ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'
            }`}
          >
            {message.text}
          </div>
        )}

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div>
            <label htmlFor="new-password" className="block text-sm font-medium text-gray-700">
              New Password
            </label>
            <input
              id="new-password"
              name="newPassword"
              type="password"
              required
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white text-gray-900"
              placeholder="Enter your new password"
              minLength={10}
            />
            <p className="mt-1 text-xs text-gray-500">
              Password must be at least 10 characters long and include uppercase, lowercase, numbers, and special characters.
            </p>
          </div>

          <div>
            <label htmlFor="confirm-password" className="block text-sm font-medium text-gray-700">
              Confirm New Password
            </label>
            <input
              id="confirm-password"
              name="confirmPassword"
              type="password"
              required
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white text-gray-900"
              placeholder="Confirm your new password"
            />
          </div>

          <div>
            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-blue-300"
            >
              {isSubmitting ? 'Processing...' : 'Reset Password'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// Main component with Suspense boundary
export default function ResetPassword() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="w-full max-w-md p-8 space-y-8 bg-white rounded-xl shadow-md">
          <p className="text-center text-gray-600">Loading...</p>
        </div>
      </div>
    }>
      <ResetPasswordContent />
    </Suspense>
  );
}