'use client';

import { useEffect, useRef } from 'react';

export default function Terminal() {
  const terminalRef = useRef(null);
  const terminalContainerRef = useRef(null);

  useEffect(() => {
    const initTerminal = async () => {
      // Dynamically import terminal libraries on the client side
      const { Terminal } = await import('@xterm/xterm');
      const { FitAddon } = await import('@xterm/addon-fit');
      const { WebLinksAddon } = await import('@xterm/addon-web-links');

      // Import styles
      await import('@xterm/xterm/css/xterm.css');

      if (!terminalContainerRef.current) return;

      // Initialize terminal
      const terminal = new Terminal({
        cursorBlink: true,
        fontSize: 14,
        fontFamily: 'monospace',
        theme: {
          background: '#202B33',
          foreground: '#F5F8FA'
        }
      });

      // Add addons
      const fitAddon = new FitAddon();
      terminal.loadAddon(fitAddon);
      terminal.loadAddon(new WebLinksAddon());

      // Open terminal
      terminal.open(terminalContainerRef.current);
      fitAddon.fit();
      terminal.focus();

      // Welcome message
      terminal.writeln('Welcome to the IIB GPU Cluster Terminal');
      terminal.writeln('Connected to Lustre/Slurm environment');
      terminal.writeln('');
      terminal.write('$ ');

      // Handle input
      terminal.onData(data => {
        // In a real implementation, this would connect to a WebSocket backend
        if (data === '\r') {
          terminal.writeln('');
          terminal.write('$ ');
        } else {
          terminal.write(data);
        }
      });

      // Handle window resizing
      const handleResize = () => fitAddon.fit();
      window.addEventListener('resize', handleResize);

      terminalRef.current = terminal;

      // Cleanup on unmount
      return () => {
        if (terminalRef.current) {
          terminalRef.current.dispose();
        }
        window.removeEventListener('resize', handleResize);
      };
    };

    initTerminal();
  }, []);

  return (
    <div className="p-4">
      <h1 className="text-3xl font-bold mb-4">Terminal Emulator</h1>
      <div
        ref={terminalContainerRef}
        className="h-[500px] w-full border border-gray-300 rounded-md bg-gray-900"
      />
      <p className="mt-4 text-sm text-gray-500">
        This terminal provides direct access to the Lustre filesystem and Slurm job submission.
      </p>
    </div>
  );
}
