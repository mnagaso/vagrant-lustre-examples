# Using fefssv_v3.py with Collectl

This guide demonstrates how to use the Python-based Lustre jobstats collector (`fefssv_v3.py`) with collectl.

## Prerequisites

1. Install collectl:
   ```bash
   # On CentOS/RHEL
   sudo yum install collectl

   # On Debian/Ubuntu
   sudo apt-get install collectl
   ```

2. Make sure `fefssv_v3.py` is executable:
   ```bash
   chmod +x fefssv_v3.py
   ```

## Basic Usage

### Collecting Lustre Jobstats Data

To collect Lustre jobstats data using the Python plugin:

```bash
collectl --import fefssv_v3 -s+Ljobstats -omdt,d
```

This command:
- `--import fefssv_v3`: Loads the Python module
- `-s+Ljobstats`: Tells collectl to collect Lustre jobstats data
- `-omdt,d`: Sets the output format (machine readable with timestamps and detail mode)

### Different Output Formats

#### Summary Mode (default)
```bash
collectl --import fefssv_v3 -s+Ljobstats
```

#### Detail Mode (show data per volume)
```bash
collectl --import fefssv_v3 -s+Ljobstats -oD
```

#### Verbose Mode (show data per job)
```bash
collectl --import fefssv_v3 -s+Ljobstats -oV
```

### Filtering Options

You can filter data by filesystem, volume, or job ID:

```bash
# Filter by specific MDT
collectl --import fefssv_v3 -s+Ljobstats --devopts mdt=mdtname -oD

# Filter by specific OST
collectl --import fefssv_v3 -s+Ljobstats --devopts ost=ostname -oD

# Filter by filesystem
collectl --import fefssv_v3 -s+Ljobstats --devopts fs=fsname -oD

# Filter by job ID
collectl --import fefssv_v3 -s+Ljobstats --devopts jobid=jobname -oV
```

## Recording Data

To record data to a file for later analysis:

```bash
# Record to a raw collectl file
collectl --import fefssv_v3 -s+Ljobstats -f /path/to/output/dir

# Record in CSV format
collectl --import fefssv_v3 -s+Ljobstats -oD --export csv,/path/to/output.csv
```

## Analyzing Recorded Data

To play back recorded data:

```bash
collectl -p /path/to/raw/file -P
```

## Integration with the Vagrant Lustre Cluster

When using the Vagrant Lustre cluster from this repository:

1. Copy the `fefssv_v3.py` script to the MXS node:
   ```bash
   vagrant scp fefssv_v3.py mxs:~
   ```

2. SSH into the MXS node:
   ```bash
   vagrant ssh mxs
   ```

3. Run collectl with the plugin:
   ```bash
   sudo collectl --import ~/fefssv_v3 -s+Ljobstats
   ```

4. To monitor job activity, submit a job via Slurm and watch the Lustre metrics:
   ```bash
   # In one terminal:
   sudo collectl --import ~/fefssv_v3 -s+Ljobstats -oD --interval 1

   # In another terminal:
   sbatch /lustre/vagrant/lustre_test_job.sh
   ```

## Troubleshooting

If you encounter issues:

1. Make sure the script has executable permissions:
   ```bash
   chmod +x fefssv_v3.py
   ```

2. Check if collectl can find the script - provide full path:
   ```bash
   collectl --import /full/path/to/fefssv_v3.py -s+Ljobstats
   ```

3. Enable debug mode to see more detailed output:
   ```bash
   collectl --import fefssv_v3 -s+Ljobstats --debug
   ```

4. Check Python version compatibility - the script requires Python 3
