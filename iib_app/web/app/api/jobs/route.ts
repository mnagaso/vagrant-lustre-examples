import { NextResponse, NextRequest } from 'next/server';
import { connectToDatabase } from '@/lib/mongodb';
import { ObjectId } from 'mongodb';

// Define the job status type
type JobStatus = 'pending' | 'running' | 'completed' | 'failed' | 'cancelled';

// Define the job interface
interface Job {
  _id?: ObjectId;
  name: string;
  user: string;
  status: JobStatus;
  script: string;
  nodes: number;
  processors: number;
  memory: number;
  walltime: string;
  workingDirectory: string;
  submittedAt: Date;
  startedAt?: Date;
  completedAt?: Date;
  errorMessage?: string;
  output?: string;
}

// GET: Retrieve jobs
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('userId');
    const status = searchParams.get('status');
    const limit = parseInt(searchParams.get('limit') || '10');
    const page = parseInt(searchParams.get('page') || '1');
    const skip = (page - 1) * limit;

    // Build query filters
    const filter: Record<string, any> = {};
    if (userId) filter.user = userId;
    if (status) filter.status = status;

    // Connect to the database
    const { db, client } = await connectToDatabase();
    const collection = db.collection('jobs');

    // Get total count for pagination
    const total = await collection.countDocuments(filter);

    // Get jobs with pagination
    const jobs = await collection
      .find(filter)
      .sort({ submittedAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    await client.close();

    return NextResponse.json({
      jobs,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching jobs:', error);
    return NextResponse.json(
      { error: 'Failed to fetch jobs' },
      { status: 500 }
    );
  }
}

// POST: Submit a new job
export async function POST(request: Request) {
  try {
    const jobData = await request.json();

    // Validate job data
    if (!jobData.name || !jobData.user || !jobData.script) {
      return NextResponse.json(
        { error: 'Missing required job fields' },
        { status: 400 }
      );
    }

    // Connect to the database
    const { db, client } = await connectToDatabase();
    const collection = db.collection('jobs');

    // Create new job
    const newJob: Job = {
      name: jobData.name,
      user: jobData.user,
      status: 'pending',
      script: jobData.script,
      nodes: jobData.nodes || 1,
      processors: jobData.processors || 1,
      memory: jobData.memory || 1024,
      walltime: jobData.walltime || '01:00:00',
      workingDirectory: jobData.workingDirectory || '/lustre/vagrant',
      submittedAt: new Date()
    };

    const result = await collection.insertOne(newJob);
    await client.close();

    // In a real implementation, here you would submit the job to Slurm
    // using a command like: sbatch --job-name=name --nodes=nodes ...

    return NextResponse.json({
      message: 'Job submitted successfully',
      jobId: result.insertedId,
      job: { ...newJob, _id: result.insertedId }
    });
  } catch (error) {
    console.error('Error submitting job:', error);
    return NextResponse.json(
      { error: 'Failed to submit job' },
      { status: 500 }
    );
  }
}

// DELETE: Cancel a job
export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const jobId = searchParams.get('id');

    if (!jobId) {
      return NextResponse.json(
        { error: 'Job ID is required' },
        { status: 400 }
      );
    }

    // Connect to the database
    const { db, client } = await connectToDatabase();
    const collection = db.collection('jobs');

    // Find the job
    const job = await collection.findOne({ _id: new ObjectId(jobId) });

    if (!job) {
      await client.close();
      return NextResponse.json(
        { error: 'Job not found' },
        { status: 404 }
      );
    }

    // If job is running or pending, cancel it in Slurm
    if (job.status === 'running' || job.status === 'pending') {
      // In a real implementation, you would cancel the job using:
      // scancel job.slurmJobId

      // Update job status in database
      await collection.updateOne(
        { _id: new ObjectId(jobId) },
        {
          $set: {
            status: 'cancelled',
            completedAt: new Date()
          }
        }
      );
    }

    await client.close();

    return NextResponse.json({
      message: 'Job cancelled successfully'
    });
  } catch (error) {
    console.error('Error cancelling job:', error);
    return NextResponse.json(
      { error: 'Failed to cancel job' },
      { status: 500 }
    );
  }
}
