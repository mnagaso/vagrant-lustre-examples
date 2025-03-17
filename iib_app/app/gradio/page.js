import Head from 'next/head';

export default function Gradio() {
  return (
    <div className="p-4">
      <Head>
        <title>Gradio Interface</title>
      </Head>
      <h1 className="text-3xl font-bold">Gradio Interface</h1>
      <p className="mt-4">This is a placeholder for the Gradio interface.</p>
      <p className="mt-4">Through this interface, you can trigger Slurm jobs.</p>
    </div>
  );
}
