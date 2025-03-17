import { exec } from 'child_process';

export async function POST(req) {
  return new Promise((resolve) => {
    exec('bash job_samples/lustre_test_job.sh', (error, stdout, stderr) => {
      if (error) {
        resolve(
          new Response(
            JSON.stringify({ message: 'Error submitting job', error: stderr }),
            { status: 500, headers: { 'Content-Type': 'application/json' } }
          )
        );
      } else {
        resolve(
          new Response(
            JSON.stringify({ message: 'Job submitted successfully', output: stdout }),
            { status: 200, headers: { 'Content-Type': 'application/json' } }
          )
        );
      }
    });
  });
}

export function GET() {
  return new Response(
    JSON.stringify({ message: 'Method Not Allowed' }),
    { status: 405, headers: { 'Content-Type': 'application/json' } }
  );
}
