"use client";
'use client';
import Head from 'next/head';
import { useState } from 'react';

export default function Gradio(): JSX.Element {
  const [result, setResult] = useState<string>('');

  async function onSubmit(): Promise<void> {
    const resp = await fetch('/api/submit-slurm', { method: 'POST' });
    const data = await resp.json();
    setResult(data.message);
  }

  return (
    <div className="p-4">
      <Head>
        <title>Gradio Interface</title>
      </Head>
      <h1 className="text-3xl font-bold">Gradio Interface</h1>
      <p className="mt-4">This is a placeholder for the Gradio interface.</p>
      <p className="mt-4">Through this interface, you can trigger Slurm jobs.</p>
      <button onClick={onSubmit} className="mt-4 px-4 py-2 bg-blue-500 text-white rounded">
        Submit Slurm Job
      </button>
      {result && <p className="mt-4">{result}</p>}
    </div>
  );
}
