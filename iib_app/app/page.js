import Head from 'next/head';
import Link from 'next/link';

export default function Home() {
  return (
    <div className="p-4">
      <Head>
        <title>IIB Inference App</title>
      </Head>
      <h1 className="text-3xl font-bold">IIB Inference App</h1>
      <p className="mt-4">Welcome to the Inference Application for the IIB GPU cluster.</p>
      <div className="mt-6 space-x-4">
        <Link href="/terminal" className="text-blue-500 underline">Open Terminal Emulator</Link>
        <Link href="/gradio" className="text-blue-500 underline">Open Gradio Interface</Link>
      </div>
    </div>
  );
}
