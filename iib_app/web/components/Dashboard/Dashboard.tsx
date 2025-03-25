"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";

// Define proper TypeScript interfaces
interface SlurmJob {
  id: string;
  name: string;
  status: 'running' | 'pending' | 'completed';
  user: string;
  nodes: number;
}

interface DiskUsage {
  used: number;
  total: number;
}

export default function Dashboard() {
  const router = useRouter();
  const [lustreStatus, setLustreStatus] = useState<'loading' | 'online' | 'offline'>('loading');
  const [slurmJobs, setSlurmJobs] = useState<SlurmJob[]>([]);
  const [diskUsage, setDiskUsage] = useState<DiskUsage>({used: 0, total: 0});
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Check authentication
    const token = localStorage.getItem('authToken');
    if (!token) {
      router.push('/');
      return;
    }

    // Simulate fetching data
    const fetchClusterData = async () => {
      try {
        // In a real implementation, these would be actual API calls
        // For demo purposes, we'll use mock data

        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 1500));

        setLustreStatus('online');
        setSlurmJobs([
          { id: 'job_123', name: 'simulation_1', status: 'running', user: 'researcher1', nodes: 2 },
          { id: 'job_124', name: 'data_analysis', status: 'pending', user: 'researcher2', nodes: 1 },
          { id: 'job_125', name: 'ml_training', status: 'completed', user: 'researcher1', nodes: 4 },
        ]);
        setDiskUsage({used: 1.2, total: 10});
        setIsLoading(false);
      } catch (error) {
        console.error("Error fetching cluster data:", error);
        setIsLoading(false);
      }
    };

    fetchClusterData();
  }, [router]);

  const handleLogout = () => {
    localStorage.removeItem('authToken');
    router.push('/');
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <p className="text-gray-600">Loading cluster data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <div className="flex items-center space-x-4">
            <Image
              src="/models3.svg"
              alt="WMT-AGIS logo"
              width={90}
              height={24}
              className="grayscale hover:grayscale-0 transition-all duration-300"
            />
            <h1 className="text-xl font-semibold text-gray-800">IIB Cluster Dashboard</h1>
          </div>
          <button
            onClick={handleLogout}
            className="text-sm text-gray-600 hover:text-gray-900"
          >
            Sign Out
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Status Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          {/* Lustre Status */}
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-medium text-gray-900 mb-2">Lustre Status</h2>
            <div className="flex items-center">
              <div className={`w-3 h-3 rounded-full mr-2 ${lustreStatus === 'online' ? 'bg-green-500' : 'bg-red-500'}`}></div>
              <p className="text-gray-700 capitalize">{lustreStatus}</p>
            </div>
          </div>

          {/* Disk Usage */}
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-medium text-gray-900 mb-2">Storage Usage</h2>
            <div className="flex flex-col">
              <div className="w-full bg-gray-200 rounded-full h-2.5 mb-2">
                <div
                  className="bg-blue-600 h-2.5 rounded-full"
                  style={{ width: `${(diskUsage.used / diskUsage.total) * 100}%` }}
                ></div>
              </div>
              <p className="text-gray-700">{diskUsage.used}TB / {diskUsage.total}TB</p>
            </div>
          </div>

          {/* Active Jobs */}
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-medium text-gray-900 mb-2">Active Jobs</h2>
            <p className="text-2xl font-semibold">{slurmJobs.filter(job => job.status === 'running').length}</p>
            <p className="text-sm text-gray-600">{slurmJobs.filter(job => job.status === 'pending').length} pending</p>
          </div>
        </div>

        {/* Slurm Jobs Table */}
        <div className="bg-white p-6 rounded-lg shadow mb-8">
          <h2 className="text-lg font-medium text-gray-900 mb-4">Recent Jobs</h2>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nodes</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {slurmJobs.map((job) => (
                  <tr key={job.id}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{job.id}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{job.name}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full
                        ${job.status === 'running' ? 'bg-green-100 text-green-800' :
                          job.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                          'bg-gray-100 text-gray-800'}`}>
                        {job.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{job.user}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{job.nodes}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Submit Job Button */}
        <div className="flex justify-end">
          <button
            className="bg-black text-white py-2 px-4 rounded-sm text-sm font-medium hover:bg-gray-800 focus:outline-none focus:ring-1 focus:ring-black"
          >
            Submit New Job
          </button>
        </div>
      </main>
    </div>
  );
}