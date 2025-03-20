import React from 'react';
import { useEffect, useState } from 'react';
import SyntaxHighlighter from 'react-syntax-highlighter';
import { atomDark } from 'react-syntax-highlighter/dist/cjs/styles/hljs';
import CommandInput from '../components/ui/CommandInput';

export default function TerminalPage() {
  const [commandHistory, setCommandHistory] = useState<string[]>([]);
  const [commandOutput, setCommandOutput] = useState<string>('');
  const [currentCommand, setCurrentCommand] = useState('');

  // Simulate command execution
  const executeCommand = (cmd: string) => {
    if (!cmd.trim()) return;

    const output = `Executing: ${cmd}\nResult: Command executed successfully`;
    setCommandHistory([...commandHistory, cmd]);
    setCommandOutput(output);
    setCurrentCommand('');
  };

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-2xl font-bold mb-4">Terminal</h2>

      {/* Command Input Area */}
      <div className="mb-6">
        <div className="flex space-x-2">
          <input
            type="text"
            value={currentCommand}
            onChange={(e) => setCurrentCommand(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && executeCommand(currentCommand)}
            placeholder="Enter command..."
            className="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />

          {/* Common Commands */}
          <div className="space-y-1">
            <button
              onClick={() => executeCommand('ls')}
              className="px-3 py-1 bg-gray-100 rounded hover:bg-gray-200 transition-colors"
            >
              <span className="flex items-center">
                <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                </svg>
                ls
              </span>
            </button>

            <button
              onClick={() => executeCommand('pwd')}
              className="px-3 py-1 bg-gray-100 rounded hover:bg-gray-200 transition-colors"
            >
              <span className="flex items-center">
                <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                </svg>
                pwd
              </span>
            </button>
          </div>
        </div>
      </div>

      {/* Command History and Output */}
      <div className="h-96 overflow-y-auto">
        {commandHistory.map((cmd, index) => (
          <div key={index} className="mb-2 p-2 bg-gray-50 rounded">
            <SyntaxHighlighter
              language="bash"
              style={atomDark}
              customStyle={{ background: 'transparent' }}
            >
              {cmd}
            </SyntaxHighlighter>
            <div className="mt-1 text-sm text-gray-500">Command executed at: {new Date().toLocaleTimeString()}</div>
          </div>
        ))}

        {commandOutput && (
          <div className="mt-4 p-3 bg-gray-800 text-white rounded">
            <h3 className="font-bold mb-2">Output:</h3>
            <pre>{commandOutput}</pre>
          </div>
        )}
      </div>

      {/* Expandable Job Results */}
      <details className="mt-6">
        <summary className="flex items-center space-x-2 cursor-pointer hover:bg-gray-100 p-2 rounded">
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
          <span>Recent Job Outputs</span>
        </summary>

        <div className="pl-4 mt-2">
          {/* Add job results here */}
          <div className="p-3 bg-gray-50 rounded mb-2">
            <h4 className="font-semibold mb-1">Job 123456</h4>
            <p className="text-sm text-gray-600">Completed successfully at 10:30 AM</p>
          </div>
        </div>
      </details>
    </div>
  );
}
