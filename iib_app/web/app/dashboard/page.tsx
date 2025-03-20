'use client';

import { useRouter } from 'next/navigation';
import {
  Card,
  CardHeader,
  CardContent,
  Typography,
  Button,
} from '@mui/material';
import { useEffect, useState } from 'react';
import SyntaxHighlighter from 'react-syntax-highlighter';
import { atomDark } from 'react-syntax-highlighter/dist/cjs/styles/hljs';

export default function Dashboard() {
  const router = useRouter();
  const [jobs, setJobs] = useState([]);

  // Simulate fetching job data
  useEffect(() => {
    const sampleJobs = [
      { id: 123456, name: 'ML Training', status: 'Running' },
      { id: 789012, name: 'Data Processing', status: 'Completed' },
    ];
    setJobs(sampleJobs);
  }, []);

  const handleLogout = () => {
    router.push('/');
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6 md:p-8">
      <div className="mx-auto max-w-7xl">
        <div className="mb-8 flex flex-col items-start justify-between space-y-4 sm:flex-row sm:items-center sm:space-y-0">
          <Typography variant="h1" component="h1" className="text-3xl font-bold text-blue-800">
            IIB HPC Dashboard
          </Typography>
          <Button
            onClick={handleLogout}
            variant="contained"
            color="error"
            className="rounded bg-red-600 px-4 py-2 font-medium text-white transition-colors duration-200 ease-in-out hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2"
          >
            Logout
          </Button>
        </div>

        <div className="space-y-6">
          {/* System Status Card */}
          <Card className="rounded-lg bg-white shadow-md">
            <CardHeader title="System Status" />
            <CardContent>
              <Typography className="mb-4 text-gray-700">
                Cluster utilization: 65%
              </Typography>
              <Typography className="mb-4 text-gray-700">
                Free storage: 2.3 TB
              </Typography>
              <Typography className="mb-4 text-gray-700">
                Available nodes: 12/20
              </Typography>
            </CardContent>
          </Card>

          {/* Recent Jobs */}
          <Card className="rounded-lg bg-white shadow-md">
            <CardHeader title="Recent Jobs" />
            <CardContent>
              {jobs.map((job) => (
                <div key={job.id} className="mb-4 p-3 border rounded">
                  <Typography className="font-semibold">{job.name}</Typography>
                  <Typography className="text-sm text-gray-600">Status: {job.status}</Typography>
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Button
              variant="contained"
              color="primary"
              fullWidth
              className="rounded-lg p-3 text-white hover:bg-blue-700"
              onClick={() => router.push('/terminal')}
            >
              Open Terminal
            </Button>
            <Button
              variant="outlined"
              color="secondary"
              fullWidth
              className="rounded-lg p-3 text-gray-900 hover:bg-gray-100"
              onClick={() => router.push('/dashboard/jobs')}
            >
              View All Jobs
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
