import React from 'react';

interface CommandInputProps {
  onClick: () => void;
}

export default function CommandInput({ onClick }: CommandInputProps) {
  return (
    <button
      onClick={onClick}
      className="px-3 py-1 bg-gray-100 rounded hover:bg-gray-200 transition-colors"
    >
      <span className="flex items-center">
        <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
        </svg>
        Execute
      </span>
    </button>
  );
}
