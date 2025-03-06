# Using fefssv.ph Perl Module with Collectl

This guide explains how to use the original Perl-based Lustre jobstats collector (`fefssv.ph`) with collectl.

## Overview

The `fefssv.ph` file is the original Perl implementation of the Lustre jobstats collector for collectl. It was later reimplemented in Python as `fefssv_v3.py`. Both versions provide similar functionality but the Perl version may be more compatible with older systems.

## Basic Usage

### Importing the Perl Module

To collect Lustre jobstats data using the Perl module:

```bash
collectl --import fefssv -s+Ljobstats -omdt,d
```

Note that when importing the Perl module, you don't need to include the `.ph` extension.

## Key Differences Between Perl and Python Versions

1. **Importing Syntax**: 
   - Perl version: `collectl --import fefssv -s+Ljobstats`
   - Python version: `collectl --import fefssv_v3.py -s+Ljobstats`

2. **Installation**: The Perl module must be placed where collectl can find it:
   - Typical locations: `/usr/share/collectl/`, `/usr/lib/collectl/`, or any directory in Perl's `@INC` path
   - Python modules can be in any accessible path when using full paths

3. **Troubleshooting**: If collectl can't find the Perl module, set the path explicitly:
   ```bash
   PERL5LIB=/path/to/directory collectl --import fefssv -s+Ljobstats
   ```

## Usage with the Vagrant Lustre Cluster

1. Copy the `fefssv.ph` script to the MXS node:
   ```bash
   vagrant scp fefssv.ph mxs:~
   ```

2. SSH into the MXS node:
   ```bash
   vagrant ssh mxs
   ```

3. Run collectl with the Perl module:
   ```bash
   sudo collectl --import ~/fefssv -s+Ljobstats
   ```
   
   Or move it to collectl's directory:
   ```bash
   sudo cp ~/fefssv.ph /usr/share/collectl/
   sudo collectl --import fefssv -s+Ljobstats
   ```

## Command Options

The same options available for the Python version work with the Perl version:

```bash
# Detail mode (show data per volume)
sudo collectl --import fefssv -s+Ljobstats -oD

# Verbose mode (show data per job)
sudo collectl --import fefssv -s+Ljobstats -oV

# Filter by volume type
sudo collectl --import fefssv -s+Ljobstats --devopts mdt -oD
sudo collectl --import fefssv -s+Ljobstats --devopts ost -oD

# Filter by specific volume
sudo collectl --import fefssv -s+Ljobstats --devopts mdt=mdtname -oD
sudo collectl --import fefssv -s+Ljobstats --devopts ost=ostname -oD

# Filter by filesystem
sudo collectl --import fefssv -s+Ljobstats --devopts fs=fsname -oD

# Filter by job ID
sudo collectl --import fefssv -s+Ljobstats --devopts jobid=jobname -oV
```

## Comparing Perl and Python Output

If you want to compare the output of both versions to ensure consistency:

```bash
# Run both versions and save their output
sudo collectl --import fefssv -s+Ljobstats -oD --export csv,/tmp/perl_output.csv
sudo collectl --import fefssv_v3.py -s+Ljobstats -oD --export csv,/tmp/python_output.csv

# Compare the outputs
diff /tmp/perl_output.csv /tmp/python_output.csv
```

Both implementations should produce essentially the same data, with potentially minor formatting differences.
