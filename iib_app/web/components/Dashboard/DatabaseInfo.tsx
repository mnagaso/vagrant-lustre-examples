'use client';

import { useState, useEffect } from 'react';

interface User {
  _id: string;
  username: string;
  role: string;
  createdAt: string;
}

interface ClusterStatus {
  _id: string;
  timestamp: string;
  nodes: {
    total: number;
    available: number;
    down: number;
  };
  filesystem: {
    totalSpace: number;
    usedSpace: number;
    availableSpace: number;
  };
}

interface Job {
  _id: string;
  job_id: string;
  user: string;
  status: string;
  submitted_at: string;
  name: string;
  queue: string;
}

export default function DatabaseInfo() {
  const [users, setUsers] = useState<User[]>([]);
  const [clusterStatus, setClusterStatus] = useState<ClusterStatus | null>(null);
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState({
    users: true,
    status: true,
    jobs: true
  });
  const [error, setError] = useState({
    users: '',
    status: '',
    jobs: ''
  });

  useEffect(() => {
    // Fetch users
    const fetchUsers = async () => {
      try {
        const response = await fetch('/api/users');
        if (!response.ok) throw new Error('Failed to fetch users');
        const data = await response.json();
        setUsers(data.users);
      } catch (err) {
        setError(prev => ({ ...prev, users: err instanceof Error ? err.message : 'Unknown error' }));
      } finally {
        setLoading(prev => ({ ...prev, users: false }));
      }
    };

    // Fetch cluster status
    const fetchClusterStatus = async () => {
      try {
        const response = await fetch('/api/cluster/status');
        if (!response.ok) throw new Error('Failed to fetch cluster status');
        const data = await response.json();
        setClusterStatus(data.status);
      } catch (err) {
        setError(prev => ({ ...prev, status: err instanceof Error ? err.message : 'Unknown error' }));
      } finally {
        setLoading(prev => ({ ...prev, status: false }));
      }
    };

    // Fetch jobs
    const fetchJobs = async () => {
      try {
        const response = await fetch('/api/jobs?limit=5');
        if (!response.ok) throw new Error('Failed to fetch jobs');
        const data = await response.json();
        setJobs(data.jobs);
      } catch (err) {
        setError(prev => ({ ...prev, jobs: err instanceof Error ? err.message : 'Unknown error' }));
      } finally {
        setLoading(prev => ({ ...prev, jobs: false }));
      }
    };

    fetchUsers();
    fetchClusterStatus();
    fetchJobs();
  }, []);

  return (
    <div className="space-y-8">
      <div className="border border-gray-200 rounded-sm p-4">
        <h2 className="text-lg font-medium mb-4">Users</h2>
        {loading.users ? (
          <p className="text-gray-500">Loading users...</p>
        ) : error.users ? (
          <p className="text-gray-700">{error.users}</p>
        ) : users.length === 0 ? (
          <p className="text-gray-500">No users found</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead>
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Username</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {users.map(user => (
                  <tr key={user._id}>
                    <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-900">{user.username}</td>
                    <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{user.role}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="border border-gray-200 rounded-sm p-4">
        <h2 className="text-lg font-medium mb-4">Cluster Status</h2>
        {loading.status ? (
          <p className="text-gray-500">Loading cluster status...</p>
        ) : error.status ? (
          <p className="text-gray-700">{error.status}</p>
        ) : !clusterStatus ? (
          <p className="text-gray-500">No cluster status available</p>
        ) : (
          <div className="grid grid-cols-2 gap-4">
            <div>
              <h3 className="text-sm font-medium text-gray-700">Nodes</h3>
              <p className="mt-1 text-sm text-gray-500">
                {clusterStatus.nodes.available}/{clusterStatus.nodes.total} nodes available
              </p>
              <p className="mt-1 text-sm text-gray-500">
                {clusterStatus.nodes.down} nodes down
              </p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-700">Filesystem</h3>
              <p className="mt-1 text-sm text-gray-500">
                {Math.round(clusterStatus.filesystem.usedSpace / clusterStatus.filesystem.totalSpace * 100)}% used
              </p>
              <p className="mt-1 text-sm text-gray-500">
                {(clusterStatus.filesystem.availableSpace / 1024 / 1024 / 1024).toFixed(2)} GB free
              </p>
            </div>
          </div>
        )}
      </div>

      <div className="border border-gray-200 rounded-sm p-4">
        <h2 className="text-lg font-medium mb-4">Recent Jobs</h2>
        {loading.jobs ? (
          <p className="text-gray-500">Loading jobs...</p>
        ) : error.jobs ? (
          <p className="text-gray-700">{error.jobs}</p>
        ) : jobs.length === 0 ? (
          <p className="text-gray-500">No jobs found</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead>
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Submitted</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {jobs.map(job => (
                  <tr key={job._id}>
                    <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-900">{job.job_id}</td>
                    <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-900">{job.name}</td>
                    <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{job.user}</td>
                    <td className="px-3 py-2 whitespace-nowrap text-sm">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-sm text-xs font-medium ${
                        job.status === 'RUNNING' ? 'bg-green-100 text-green-800' :
                        job.status === 'PENDING' ? 'bg-yellow-100 text-yellow-800' :
                        job.status === 'COMPLETED' ? 'bg-blue-100 text-blue-800' :
                        job.status === 'FAILED' ? 'bg-red-100 text-red-800' :
                        'bg-gray-100 text-gray-800'
                      }`}>
                        {job.status}
                      </span>
                    </td>
                    <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">
                      {new Date(job.submitted_at).toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
