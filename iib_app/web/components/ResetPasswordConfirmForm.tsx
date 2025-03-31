'use client';
import React, { useState } from 'react';

const ResetPasswordConfirmForm = () => {
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password !== confirmPassword) {
      alert('Passwords do not match!');
      return;
    }
    // Add logic to handle password reset confirmation
    console.log('Password reset confirmed with new password:', password);
  };

  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="password">New Password:</label>
      <input
        type="password"
        id="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white text-gray-900 mb-4"
        required
      />
      <label htmlFor="confirmPassword">Confirm Password:</label>
      <input
        type="password"
        id="confirmPassword"
        value={confirmPassword}
        onChange={(e) => setConfirmPassword(e.target.value)}
        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white text-gray-900 mb-4"
        required
      />
      <button type="submit">Confirm Reset</button>
    </form>
  );
};

export default ResetPasswordConfirmForm;
