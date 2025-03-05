#!/usr/bin/env python3
"""
Lustre Jobstats data collection script

This module collects and processes Lustre Jobstats data.
Python implementation of the Perl fefssv.ph script with Pythonic improvements.

Copyright(c) 2015,2018 FUJITSU LIMITED.
All rights reserved.
"""

import os
import sys
import time
import re
import subprocess
import glob
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Set, Tuple, Union, Any, Callable
from collections import defaultdict
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('fefssv_v3')

# Constants
UNUSED_MARK = "unused_mark"

# Data type lists
DATA_TYPE_LIST = {
    'mdt': [
        "open", "close", "mknod", "link", "unlink", "mkdir", "rmdir", "rename",
        "getattr", "setattr", "getxattr", "setxattr", "statfs", "sync",
        "samedir_rename", "crossdir_rename"
    ],
    'ost': [
        "read", "read_bytes", "write", "write_bytes", "getattr", "setattr",
        "punch", "sync", "destroy", "create", "statfs", "get_info", "set_info", "quotactl"
    ]
}

@dataclass
class FefssvState:
    """Class to encapsulate the state of the fefssv module"""
    # Global variables to mirror collectl variables
    miniFiller: str = ""
    SEP: str = ":"
    datetime_str: str = ""
    showColFlag: bool = False
    options: str = ""
    filename: str = ""
    plotFlag: bool = False
    lastSeconds: List[str] = field(default_factory=list)
    rawPFlag: int = 0
    intSeconds: int = 0
    intUsecs: int = 0
    utcFlag: bool = False
    hiResFlag: bool = False

    # Module-specific global variables
    lj_data_out: Dict[str, Dict[str, Dict[str, int]]] = field(default_factory=lambda: defaultdict(lambda: defaultdict(dict)))
    lj_data_last: Dict[str, Dict[str, Dict[str, int]]] = field(default_factory=lambda: defaultdict(lambda: defaultdict(dict)))
    find_flg: Dict[str, Dict[str, int]] = field(default_factory=lambda: defaultdict(dict))
    volname: str = UNUSED_MARK
    jobid: str = UNUSED_MARK
    target_fs: str = UNUSED_MARK
    target_vol: str = UNUSED_MARK
    target_job: str = UNUSED_MARK
    vol_type: str = UNUSED_MARK
    mode: str = "summary"
    target_vol_flg: int = 1
    target_job_flg: int = 1
    fefs_ver: float = 2.6

# Create a global state instance
state = FefssvState()

class FefssvError(Exception):
    """Custom exception for fefssv errors"""
    pass

def error(message: str) -> None:
    """Print error message and exit"""
    logger.error(message)
    raise FefssvError(message)

def fefssvInit(impOptsref: List[str], impKeyref: List[str]) -> int:
    """Initialize fefssv module with improved option handling"""
    global state

    PKG_NAME = "FJSVfefs"
    CMD = f"/bin/rpm -q {PKG_NAME} 2>&1"

    # Check options using a more Pythonic dictionary-based approach
    if impOptsref and impOptsref[0]:
        options = impOptsref[0].split(',')
        option_map = {}

        # Parse options into a dictionary
        for opt in options:
            if '=' in opt:
                name, value = opt.split('=', 1)
            else:
                name, value = opt, None
            option_map[name] = value

        # Process options with more Pythonic checks
        if 'd' in option_map and 'v' in option_map:
            error("fefssv : v and d options can't be used at the same time.")

        if 'd' in option_map:
            state.mode = "detail"
        elif 'v' in option_map:
            state.mode = "verbose"

        if 'mdt' in option_map and 'ost' in option_map:
            error("fefssv : mdt and ost options can't be used at the same time.")

        if 'mdt' in option_map:
            state.vol_type = "mdt"
            if option_map['mdt']:
                state.target_vol = f"/{option_map['mdt']}/"
        elif 'ost' in option_map:
            state.vol_type = "ost"
            if option_map['ost']:
                state.target_vol = f"/{option_map['ost']}/"

        if 'fs' in option_map and option_map['fs']:
            state.target_fs = f"/{option_map['fs']}/"

        if 'jobid' in option_map and option_map['jobid']:
            state.target_job = f"/{option_map['jobid']}/"

        # Validate combinations
        invalid_options = set(option_map) - {'d', 'v', 'mdt', 'ost', 'fs', 'jobid'}
        if invalid_options:
            error(f"fefssv : invalid option(s): {', '.join(invalid_options)}")

    # Error checks with clearer conditions
    if not (state.filename and not state.plotFlag) and state.vol_type == UNUSED_MARK:
        error("fefssv : mdt or ost option is required if you print out the data.")

    if state.target_vol != UNUSED_MARK and state.target_fs != UNUSED_MARK:
        error("fefssv : can't specify a volume when you use fs option.")

    if state.target_fs != UNUSED_MARK and state.mode == 'summary':
        error("fefssv : v or d option is required when you use fs option.")

    if state.target_vol != UNUSED_MARK and state.mode == 'summary':
        error("fefssv : v or d option is required when you specify the volumes.")

    if state.target_job != UNUSED_MARK and state.mode != 'verbose':
        error("fefssv : v option is required when you use jobid option.")

    # Set return option
    impOptsref[0] = "s" if state.mode == 'summary' else "d"

    # Check fefs version with better error handling
    try:
        fefs_pkg = subprocess.check_output(CMD, shell=True, universal_newlines=True)
        state.fefs_ver = 1.8 if re.search(r'FJSVfefs-1\.[0-9]\.[0-9]-', fefs_pkg) else 2.6
    except subprocess.CalledProcessError:
        logger.warning("Failed to detect FEFS version, using default (2.6)")

    # Set fefssv key
    impKeyref[0] = 'Ljobstats'
    return 1

def fefssvInitInterval() -> None:
    """Initialize data for new interval"""
    global state

    # Reset output data and find flag
    state.lj_data_out.clear()
    state.find_flg.clear()

    # Initialize all counters with a more Pythonic approach
    if state.vol_type in DATA_TYPE_LIST:
        state.lj_data_out.setdefault('all', {}).setdefault('all', {})
        for dt in DATA_TYPE_LIST[state.vol_type]:
            state.lj_data_out['all']['all'][dt] = 0

def fefssvGetData() -> None:
    """Collect Lustre jobstats data with better path handling"""
    # Get mdt jobstats data
    mdt_patterns = ["/proc/fs/lustre/mdt/*/job_stats", "/proc/fs/lustre/mds/*/job_stats"]
    mdt_check = sum([glob.glob(pattern) for pattern in mdt_patterns], [])

    if mdt_check:
        try:
            getExec('/usr/sbin/lctl get_param mdt.*.job_stats', 'Ljobstats-mdt')
        except (subprocess.SubprocessError, OSError) as e:
            logger.warning(f"Error getting MDT stats: {e}")

        try:
            getExec('/usr/sbin/lctl get_param mds.*.job_stats', 'Ljobstats-mdt')
        except (subprocess.SubprocessError, OSError) as e:
            logger.warning(f"Error getting MDS stats: {e}")

    # Get ost jobstats data
    ost_check = glob.glob("/proc/fs/lustre/obdfilter/*/job_stats")
    if ost_check:
        try:
            getExec('/usr/sbin/lctl get_param obdfilter.*.job_stats', 'Ljobstats-ost')
        except (subprocess.SubprocessError, OSError) as e:
            logger.warning(f"Error getting OST stats: {e}")

def getExec(cmd: str, tag: str) -> None:
    """Execute command and process output with improved error handling"""
    try:
        output = subprocess.check_output(cmd, shell=True, universal_newlines=True)

        # Process all lines in a more Pythonic way
        for line in output.splitlines():
            if line.strip():
                fefssvAnalyze(f"{tag}:", line)
    except subprocess.CalledProcessError as e:
        logger.warning(f"Command failed with exit code {e.returncode}: {cmd}")
    except Exception as e:
        logger.exception(f"Error executing command {cmd}: {e}")

def fefssvAnalyze(type_str: str, data: str) -> None:
    """Analyze Lustre Jobstats data with better regex handling"""
    global state

    # Early return if the type doesn't match
    if type_str != f"Ljobstats-{state.vol_type}:":
        return

    # Extract data_type using safer regex
    match = re.search(r'^[\-\s]*(\S+)[:=]', data)
    if not match:
        return

    data_type = match.group(1)

    # Process volume data
    match = re.search(r'^\S+\.(\S+\-\S+)\.job_stats', data_type)
    if match:
        state.volname = match.group(1)

        # Handle filesystem or volume targeting
        if state.target_fs != UNUSED_MARK:
            fs_match = re.search(r'^(\S+)\-\S+', state.volname)
            if fs_match and re.search(fr'\/{fs_match.group(1)}\/', state.target_fs):
                state.target_vol_flg = 1
            else:
                state.target_vol_flg = 0
        elif state.target_vol != UNUSED_MARK:
            state.target_vol_flg = 1 if re.search(fr'\/{state.volname}\/', state.target_vol) else 0

        # Initialize counters for this volume if it's targeted
        if state.target_vol_flg == 1:
            state.lj_data_out.setdefault(state.volname, {}).setdefault('all', {})
            for dt in DATA_TYPE_LIST.get(state.vol_type, []):
                state.lj_data_out[state.volname]['all'][dt] = 0

        return

    # Skip if volume not targeted
    if state.target_vol_flg == 0:
        return

    # Process job ID
    if data_type == 'job_id':
        jobid_match = re.search(r'job_id:\s*(\S+)', data)
        if not jobid_match:
            return

        state.jobid = jobid_match.group(1)

        # Check if this job is targeted
        if state.target_job != UNUSED_MARK:
            state.target_job_flg = 1 if re.search(fr'\/{re.escape(state.jobid)}\/', state.target_job) else 0

        # Initialize job counters if targeted
        if state.target_job_flg == 1:
            state.find_flg.setdefault(state.volname, {})[state.jobid] = 1
            state.lj_data_out.setdefault(state.volname, {}).setdefault(state.jobid, {})
            for dt in DATA_TYPE_LIST.get(state.vol_type, []):
                state.lj_data_out[state.volname][state.jobid][dt] = 0

        return

    # Skip if job not targeted
    if state.target_job_flg == 0:
        return

    # Process read and read_bytes stats
    if data_type == 'read' or data_type == 'read_bytes':
        match = re.search(r'samples:\s*(\d+),.*sum:\s*(\d+)\s\}', data)
        if match:
            read = int(match.group(1))
            read_bytes = int(match.group(2))

            # Use dictionary's get method for safer access
            last_jobid_dict = state.lj_data_last.get(state.volname, {}).get(state.jobid, {})

            # Compute delta values with better conditionals
            if 'read' in last_jobid_dict:
                state.lj_data_out[state.volname][state.jobid]['read'] = read - last_jobid_dict['read'] if read >= last_jobid_dict['read'] else read
                state.lj_data_out[state.volname][state.jobid]['read_bytes'] = read_bytes - last_jobid_dict['read_bytes'] if read_bytes >= last_jobid_dict['read_bytes'] else read_bytes
            else:
                state.lj_data_out[state.volname][state.jobid]['read'] = read
                state.lj_data_out[state.volname][state.jobid]['read_bytes'] = read_bytes

            # Store last values
            vol_dict = state.lj_data_last.setdefault(state.volname, {})
            jobid_dict = vol_dict.setdefault(state.jobid, {})
            jobid_dict['read'] = read
            jobid_dict['read_bytes'] = read_bytes

            # Update volume and global totals
            state.lj_data_out[state.volname]['all']['read'] = state.lj_data_out[state.volname]['all'].get('read', 0) + state.lj_data_out[state.volname][state.jobid]['read']
            state.lj_data_out[state.volname]['all']['read_bytes'] = state.lj_data_out[state.volname]['all'].get('read_bytes', 0) + state.lj_data_out[state.volname][state.jobid]['read_bytes']

            state.lj_data_out['all']['all']['read'] = state.lj_data_out['all']['all'].get('read', 0) + state.lj_data_out[state.volname][state.jobid]['read']
            state.lj_data_out['all']['all']['read_bytes'] = state.lj_data_out['all']['all'].get('read_bytes', 0) + state.lj_data_out[state.volname][state.jobid]['read_bytes']

    # Process write and write_bytes stats
    elif data_type == 'write' or data_type == 'write_bytes':
        match = re.search(r'samples:\s*(\d+),.*sum:\s*(\d+)\s\}', data)
        if match:
            write = int(match.group(1))
            write_bytes = int(match.group(2))

            last_jobid_dict = state.lj_data_last.get(state.volname, {}).get(state.jobid, {})

            if 'write' in last_jobid_dict:
                state.lj_data_out[state.volname][state.jobid]['write'] = write - last_jobid_dict['write'] if write >= last_jobid_dict['write'] else write
                state.lj_data_out[state.volname][state.jobid]['write_bytes'] = write_bytes - last_jobid_dict['write_bytes'] if write_bytes >= last_jobid_dict['write_bytes'] else write_bytes
            else:
                state.lj_data_out[state.volname][state.jobid]['write'] = write
                state.lj_data_out[state.volname][state.jobid]['write_bytes'] = write_bytes

            vol_dict = state.lj_data_last.setdefault(state.volname, {})
            jobid_dict = vol_dict.setdefault(state.jobid, {})
            jobid_dict['write'] = write
            jobid_dict['write_bytes'] = write_bytes

            state.lj_data_out[state.volname]['all']['write'] = state.lj_data_out[state.volname]['all'].get('write', 0) + state.lj_data_out[state.volname][state.jobid]['write']
            state.lj_data_out[state.volname]['all']['write_bytes'] = state.lj_data_out[state.volname]['all'].get('write_bytes', 0) + state.lj_data_out[state.volname][state.jobid]['write_bytes']

            state.lj_data_out['all']['all']['write'] = state.lj_data_out['all']['all'].get('write', 0) + state.lj_data_out[state.volname][state.jobid]['write']
            state.lj_data_out['all']['all']['write_bytes'] = state.lj_data_out['all']['all'].get('write_bytes', 0) + state.lj_data_out[state.volname][state.jobid]['write_bytes']

    # Process other stats
    elif data_type not in ['job_stats', 'snapshot_time']:
        match = re.search(r'samples:\s*(\d+),', data)
        if match:
            exec_cnt = int(match.group(1))

            last_jobid_dict = state.lj_data_last.get(state.volname, {}).get(state.jobid, {})

            if data_type in last_jobid_dict:
                state.lj_data_out[state.volname][state.jobid][data_type] = exec_cnt - last_jobid_dict[data_type] if exec_cnt >= last_jobid_dict[data_type] else exec_cnt
            else:
                state.lj_data_out[state.volname][state.jobid][data_type] = exec_cnt

            vol_dict = state.lj_data_last.setdefault(state.volname, {})
            jobid_dict = vol_dict.setdefault(state.jobid, {})
            jobid_dict[data_type] = exec_cnt

            state.lj_data_out[state.volname]['all'][data_type] = state.lj_data_out[state.volname]['all'].get(data_type, 0) + state.lj_data_out[state.volname][state.jobid][data_type]
            state.lj_data_out['all']['all'][data_type] = state.lj_data_out['all']['all'].get(data_type, 0) + state.lj_data_out[state.volname][state.jobid][data_type]

def fefssvIntervalEnd() -> None:
    """Process end of interval with a more Pythonic approach"""
    global state

    # Clear not found data using dict comprehension
    state.lj_data_last = {
        vol: {
            job: job_data
            for job, job_data in vol_data.items()
            if vol in state.find_flg and job in state.find_flg[vol]
        }
        for vol, vol_data in state.lj_data_last.items()
    }

def fefssvPrintBrief(type_num: int, line_ref: List[str]) -> str:
    """Print brief output format with f-strings and improved formatting"""
    global state

    line = ""

    # Create header and data line for brief
    if type_num == 1:
        if state.vol_type == 'mdt':
            header_text = "Lustre Jobstats"
            if state.fefs_ver == 2.6:
                line = f"<{'-'*70}{header_text}{'-'*71}>"
            else:
                line = f"<{'-'*54}{header_text}{'-'*55}>"
        else:
            header_text = "Lustre Jobstats"
            if state.fefs_ver == 2.6:
                line = f"<{'-'*60}{header_text}{'-'*61}>"
            else:
                line = f"<{'-'*29}{header_text}{'-'*29}>"

    elif type_num == 2:
        if state.vol_type == 'mdt':
            columns = DATA_TYPE_LIST['mdt']
            if state.fefs_ver != 2.6:
                columns = [col for col in columns if col not in ['samedir_rename', 'crossdir_rename']]
            line = "    " + "    ".join(f"{col:<8}" for col in columns)
        else:
            if state.fefs_ver == 2.6:
                columns = DATA_TYPE_LIST['ost']
                line = "    " + "    ".join(f"{col:<8}" if not col.endswith('bytes') else f"{col}[B]" for col in columns)
            else:
                columns = ['read', 'read_bytes', 'write', 'write_bytes', 'setattr', 'punch', 'sync']
                line = "    " + "    ".join(f"{col:<8}" if not col.endswith('bytes') else f"{col}[B]" for col in columns)

    elif type_num == 3:
        if state.vol_type == 'mdt':
            if state.fefs_ver == 2.6:
                values = [state.lj_data_out['all']['all'].get(dt, 0) for dt in DATA_TYPE_LIST['mdt']]
                formats = [8] * 14 + [15] * 2  # Special width for last two fields
                line = " ".join(f"{val:{width}}" for val, width in zip(values, formats))
            else:
                values = [state.lj_data_out['all']['all'].get(dt, 0) for dt in DATA_TYPE_LIST['mdt'] if dt not in ['samedir_rename', 'crossdir_rename']]
                line = " ".join(f"{val:8}" for val in values)
        else:
            if state.fefs_ver == 2.6:
                values = []
                for dt in DATA_TYPE_LIST['ost']:
                    val = state.lj_data_out['all']['all'].get(dt, 0)
                    if dt.endswith('bytes'):
                        values.append(f"{val:14}")
                    else:
                        values.append(f"{val:8}")
                line = " ".join(values)
            else:
                dts = ['read', 'read_bytes', 'write', 'write_bytes', 'setattr', 'punch', 'sync']
                values = []
                for dt in dts:
                    val = state.lj_data_out['all']['all'].get(dt, 0)
                    if dt.endswith('bytes'):
                        values.append(f"{val:14}")
                    else:
                        values.append(f"{val:8}")
                line = " ".join(values)

    line_ref.append(line)
    return line

def fefssvPrintPlot(type_num: int, line_ref: List[str]) -> str:
    """Format output for plotting with improved string handling"""
    global state

    line = ""

    # Create header and data line for plot
    if type_num == 1:
        if state.vol_type == 'mdt':
            columns = DATA_TYPE_LIST['mdt']
            if state.fefs_ver != 2.6:
                columns = [col for col in columns if col not in ['samedir_rename', 'crossdir_rename']]
            line = state.SEP.join(columns) + state.SEP
        else:
            if state.fefs_ver == 2.6:
                columns = [col if not col.endswith('bytes') else f"{col}[B]" for col in DATA_TYPE_LIST['ost']]
                line = state.SEP.join(columns) + state.SEP
            else:
                columns = ['read', 'read_bytes[B]', 'write', 'write_bytes[B]', 'setattr', 'punch', 'sync']
                line = state.SEP.join(columns) + state.SEP

    elif type_num == 2:
        if state.mode == 'verbose':
            prefix = ["MDT_NAME", "JOBID"] if state.vol_type == 'mdt' else ["OST_NAME", "JOBID"]
            if state.vol_type == 'mdt':
                columns = DATA_TYPE_LIST['mdt']
                if state.fefs_ver != 2.6:
                    columns = [col for col in columns if col not in ['samedir_rename', 'crossdir_rename']]
            else:
                if state.fefs_ver == 2.6:
                    columns = [col if not col.endswith('bytes') else f"{col}[B]" for col in DATA_TYPE_LIST['ost']]
                else:
                    columns = ['read', 'read_bytes[B]', 'write', 'write_bytes[B]', 'setattr', 'punch', 'sync']
            line = state.SEP.join(prefix + columns) + state.SEP
        else:
            prefix = ["MDT_NAME"] if state.vol_type == 'mdt' else ["OST_NAME"]
            if state.vol_type == 'mdt':
                columns = DATA_TYPE_LIST['mdt']
                if state.fefs_ver != 2.6:
                    columns = [col for col in columns if col not in ['samedir_rename', 'crossdir_rename']]
            else:
                if state.fefs_ver == 2.6:
                    columns = [col if not col.endswith('bytes') else f"{col}[B]" for col in DATA_TYPE_LIST['ost']]
                else:
                    columns = ['read', 'read_bytes[B]', 'write', 'write_bytes[B]', 'setattr', 'punch', 'sync']
            line = state.SEP.join(prefix + columns) + state.SEP

    elif type_num == 3:
        if state.vol_type == 'mdt':
            if state.fefs_ver == 2.6:
                values = [str(state.lj_data_out['all']['all'].get(dt, 0)) for dt in DATA_TYPE_LIST['mdt']]
            else:
                values = [str(state.lj_data_out['all']['all'].get(dt, 0)) for dt in DATA_TYPE_LIST['mdt']
                          if dt not in ['samedir_rename', 'crossdir_rename']]
            line = state.SEP + state.SEP.join(values)
        else:
            if state.fefs_ver == 2.6:
                values = [str(state.lj_data_out['all']['all'].get(dt, 0)) for dt in DATA_TYPE_LIST['ost']]
                line = state.SEP + state.SEP.join(values)
            else:
                dts = ['read', 'read_bytes', 'write', 'write_bytes', 'setattr', 'punch', 'sync']
                values = [str(state.lj_data_out['all']['all'].get(dt, 0)) for dt in dts]
                line = state.SEP + state.SEP.join(values)

    elif type_num == 4:
        # Remove 'all' from output data
        if 'all' in state.lj_data_out:
            del state.lj_data_out['all']

        datetime_str = format_datetime_string()

        # Handle verbose and detail modes
        if state.mode == 'verbose':
            # Remove 'all' from each volume
            for vol in state.lj_data_out:
                if 'all' in state.lj_data_out[vol]:
                    del state.lj_data_out[vol]['all']

            # Create output line for each volume and job
            for vol in sorted(state.lj_data_out.keys()):
                for job in sorted(state.lj_data_out[vol].keys()):
                    prefix = [datetime_str, vol, job]

                    if state.vol_type == 'mdt':
                        if state.fefs_ver == 2.6:
                            values = [str(state.lj_data_out[vol][job].get(dt, 0)) for dt in DATA_TYPE_LIST['mdt']]
                        else:
                            values = [str(state.lj_data_out[vol][job].get(dt, 0)) for dt in DATA_TYPE_LIST['mdt']
                                    if dt not in ['samedir_rename', 'crossdir_rename']]
                    else:
                        if state.fefs_ver == 2.6:
                            values = [str(state.lj_data_out[vol][job].get(dt, 0)) for dt in DATA_TYPE_LIST['ost']]
                        else:
                            dts = ['read', 'read_bytes', 'write', 'write_bytes', 'setattr', 'punch', 'sync']
                            values = [str(state.lj_data_out[vol][job].get(dt, 0)) for dt in dts]

                    line = state.SEP.join(prefix + values)
                    line_ref.append(line)
        else:
            # Create output line for each volume
            for vol in sorted(state.lj_data_out.keys()):
                prefix = [datetime_str, vol]

                if state.vol_type == 'mdt':
                    if state.fefs_ver == 2.6:
                        values = [str(state.lj_data_out[vol]['all'].get(dt, 0)) for dt in DATA_TYPE_LIST['mdt']]
                    else:
                        values = [str(state.lj_data_out[vol]['all'].get(dt, 0)) for dt in DATA_TYPE_LIST['mdt']
                                 if dt not in ['samedir_rename', 'crossdir_rename']]
                else:
                    if state.fefs_ver == 2.6:
                        values = [str(state.lj_data_out[vol]['all'].get(dt, 0)) for dt in DATA_TYPE_LIST['ost']]
                    else:
                        dts = ['read', 'read_bytes', 'write', 'write_bytes', 'setattr', 'punch', 'sync']
                        values = [str(state.lj_data_out[vol]['all'].get(dt, 0)) for dt in dts]

                line = state.SEP.join(prefix + values)
                line_ref.append(line)

    return line


def format_datetime_string() -> str:
    """Format datetime string with better time handling"""
    global state

    # Get seconds and microseconds using more robust handling
    seconds = None
    usecs = None

    if state.lastSeconds and len(state.lastSeconds) > state.rawPFlag:
        seconds_data = state.lastSeconds[state.rawPFlag]
        if '.' in seconds_data:
            seconds, usecs = seconds_data.split('.')
        else:
            seconds = seconds_data
            usecs = "000"
    else:
        seconds = str(state.intSeconds)
        usecs = f"{state.intUsecs:06d}"

    utc_secs = seconds

    # Format usecs consistently
    if not usecs:
        usecs = "000"  # For case when user specifies -om

    if state.hiResFlag:
        usecs = f"{usecs:0<3}"[:3]  # Zero-pad and slice for consistent length
        seconds = f"{seconds}.{usecs}"

    # Format date and time using standard library
    timestamp = int(seconds)
    time_tuple = time.localtime(timestamp)

    # Format date based on options
    if 'd' in state.options:
        date_str = f"{time_tuple.tm_mon:02d}/{time_tuple.tm_mday:02d}"
    else:
        date_str = f"{time_tuple.tm_year:04d}{time_tuple.tm_mon:02d}{time_tuple.tm_mday:02d}"

    time_str = f"{time_tuple.tm_hour:02d}:{time_tuple.tm_min:02d}:{time_tuple.tm_sec:02d}"

    # Build datetime string with f-strings
    if not state.utcFlag:
        datetime_str = f"\n{date_str}{state.SEP}{time_str}"
    else:
        datetime_str = f"\n{utc_secs}"

    # Add microseconds if requested
    if 'm' in state.options:
        datetime_str += f".{usecs}"

    return datetime_str


def fefssvPrintVerbose(print_header: bool, home_flag: bool, line_ref: List[str]) -> str:
    """Print verbose output with better formatting and list comprehensions"""
    global state

    lines = []

    if print_header:
        # Add newline for non-home output
        if not home_flag:
            lines.append("\n")

        lines.append("# Lustre Jobstats\n")

        # Create header with f-strings
        if state.mode == 'verbose':
            if state.vol_type == 'mdt':
                if state.fefs_ver == 2.6:
                    header = f"#{state.miniFiller}        MDT_NAME      JOBID     open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync  samedir_rename crossdir_rename\n"
                else:
                    header = f"#{state.miniFiller}        MDT_NAME      JOBID     open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync\n"
            else:
                if state.fefs_ver == 2.6:
                    header = f"#{state.miniFiller}        OST_NAME      JOBID     read  read_bytes[B]    write write_bytes[B]  getattr  setattr    punch     sync  destroy   create   statfs get_info set_info quotactl\n"
                else:
                    header = f"#{state.miniFiller}        OST_NAME      JOBID     read  read_bytes[B]    write write_bytes[B]  setattr    punch     sync\n"
        else:
            if state.vol_type == 'mdt':
                if state.fefs_ver == 2.6:
                    header = f"#{state.miniFiller}        MDT_NAME     open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync  samedir_rename crossdir_rename\n"
                else:
                    header = f"#{state.miniFiller}        MDT_NAME     open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync\n"
            else:
                if state.fefs_ver == 2.6:
                    header = f"#{state.miniFiller}        OST_NAME     read  read_bytes[B]    write write_bytes[B]  getattr  setattr    punch     sync  destroy   create   statfs get_info set_info quotactl\n"
                else:
                    header = f"#{state.miniFiller}        OST_NAME     read  read_bytes[B]    write write_bytes[B]  setattr    punch     sync\n"
        lines.append(header)

    # Return early if just showing column headers
    if state.showColFlag:
        line_ref.append(''.join(lines))
        return ''.join(lines)

    # Generate datetime string for output
    datetime_str = state.datetime_str

    # Remove 'all' from output data
    if 'all' in state.lj_data_out:
        del state.lj_data_out['all']

    # Create data lines based on mode
    if state.mode == 'verbose':
        # Remove 'all' from each volume for verbose mode
        for vol in state.lj_data_out:
            if 'all' in state.lj_data_out[vol]:
                del state.lj_data_out[vol]['all']

        # Format output for each volume and job using list comprehensions and join
        for vol in sorted(state.lj_data_out.keys()):
            for job in sorted(state.lj_data_out[vol].keys()):
                if state.vol_type == 'mdt':
                    if state.fefs_ver == 2.6:
                        # Get values for all MDT fields
                        values = [
                            f"{state.lj_data_out[vol][job].get(dt, 0):8d}" for dt in
                            DATA_TYPE_LIST['mdt'][:-2]
                        ]
                        # Add special formatting for last two fields
                        values.extend([
                            f"{state.lj_data_out[vol][job].get('samedir_rename', 0):15d}",
                            f"{state.lj_data_out[vol][job].get('crossdir_rename', 0):15d}"
                        ])
                        # Join all parts with proper spacing
                        line = f"{datetime_str} {vol:16s} {job:10s} " + " ".join(values) + "\n"
                    else:
                        # Get values for MDT fields excluding samedir_rename and crossdir_rename
                        values = [
                            f"{state.lj_data_out[vol][job].get(dt, 0):8d}" for dt in
                            [d for d in DATA_TYPE_LIST['mdt'] if d not in ['samedir_rename', 'crossdir_rename']]
                        ]
                        line = f"{datetime_str} {vol:16s} {job:10s} " + " ".join(values) + "\n"
                else:  # OST
                    if state.fefs_ver == 2.6:
                        # Format all OST fields - apply different width for byte fields
                        values = []
                        for dt in DATA_TYPE_LIST['ost']:
                            val = state.lj_data_out[vol][job].get(dt, 0)
                            if dt.endswith('bytes'):
                                values.append(f"{val:14d}")
                            else:
                                values.append(f"{val:8d}")
                        line = f"{datetime_str} {vol:16s} {job:10s} " + " ".join(values) + "\n"
                    else:
                        # Use a consistent approach for the limited set of OST fields
                        ost_fields = ['read', 'read_bytes', 'write', 'write_bytes', 'setattr', 'punch', 'sync']
                        values = []
                        for dt in ost_fields:
                            val = state.lj_data_out[vol][job].get(dt, 0)
                            if dt.endswith('bytes'):
                                values.append(f"{val:14d}")
                            else:
                                values.append(f"{val:8d}")
                        line = f"{datetime_str} {vol:16s} {job:10s} " + " ".join(values) + "\n"

                lines.append(line)
    else:  # Detail mode
        # Format output for each volume
        for vol in sorted(state.lj_data_out.keys()):
            if state.vol_type == 'mdt':
                if state.fefs_ver == 2.6:
                    # Get values for all MDT fields
                    values = [
                        f"{state.lj_data_out[vol]['all'].get(dt, 0):8d}" for dt in
                        DATA_TYPE_LIST['mdt'][:-2]
                    ]
                    # Add special formatting for last two fields
                    values.extend([
                        f"{state.lj_data_out[vol]['all'].get('samedir_rename', 0):15d}",
                        f"{state.lj_data_out[vol]['all'].get('crossdir_rename', 0):15d}"
                    ])
                    line = f"{datetime_str} {vol:16s} " + " ".join(values) + "\n"
                else:
                    # Get values for MDT fields excluding samedir_rename and crossdir_rename
                    values = [
                        f"{state.lj_data_out[vol]['all'].get(dt, 0):8d}" for dt in
                        [d for d in DATA_TYPE_LIST['mdt'] if d not in ['samedir_rename', 'crossdir_rename']]
                    ]
                    line = f"{datetime_str} {vol:16s} " + " ".join(values) + "\n"
            else:  # OST
                if state.fefs_ver == 2.6:
                    # Format all OST fields
                    values = []
                    for dt in DATA_TYPE_LIST['ost']:
                        val = state.lj_data_out[vol]['all'].get(dt, 0)
                        if dt.endswith('bytes'):
                            values.append(f"{val:14d}")
                        else:
                            values.append(f"{val:8d}")
                    line = f"{datetime_str} {vol:16s} " + " ".join(values) + "\n"
                else:
                    # Use a consistent approach for the limited set of OST fields
                    ost_fields = ['read', 'read_bytes', 'write', 'write_bytes', 'setattr', 'punch', 'sync']
                    values = []
                    for dt in ost_fields:
                        val = state.lj_data_out[vol]['all'].get(dt, 0)
                        if dt.endswith('bytes'):
                            values.append(f"{val:14d}")
                        else:
                            values.append(f"{val:8d}")
                    line = f"{datetime_str} {vol:16s} " + " ".join(values) + "\n"

            lines.append(line)

    # Join all lines and add to line_ref
    result = ''.join(lines)
    line_ref.append(result)
    return result

def fefssvUpdateHeader(line_ref: List[str]) -> str:
    """Update header with FEFS version information using f-strings"""
    global state

    # Create FEFS version header line using conditional expression
    version_text = "Lustre 1.8 base" if state.fefs_ver == 1.8 else "Lustre 2.6 base"
    line = f"# FEFS:       {version_text}\n"

    line_ref.append(line)
    return line

def fefssvGetHeader(data: str) -> None:
    """Extract FEFS version from header data in a more Pythonic way"""
    global state

    # Set version based on string presence - use simple string check for clarity
    state.fefs_ver = 1.8 if "FEFS:       Lustre 1.8 base" in data else 2.6

def fefssvPrintExport() -> None:
    """Export function stub - maintained for API compatibility"""
    pass

# Main execution block with more helpful information
if __name__ == "__main__":
    parser_description = """
    Lustre Jobstats data collection script (Python implementation)

    This is designed to be used with collectl or similar tools.

    Example usage:
        collectl --import fefssv_v3 -s+Ljobstats -omdt,d

    Options:
        mdt:    Monitor MDT volumes (mutually exclusive with ost)
        ost:    Monitor OST volumes (mutually exclusive with mdt)
        d:      Detail mode - show data per volume (mutually exclusive with v)
        v:      Verbose mode - show data per job (mutually exclusive with d)
        fs:     Filter by filesystem name
        jobid:  Filter by job ID
    """

    import argparse

    parser = argparse.ArgumentParser(
        description=parser_description,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('--version', action='version', version='fefssv_v3 1.0.0')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')

    args = parser.parse_args()

    if args.debug:
        logger.setLevel(logging.DEBUG)

    print("This is a module to be used with collectl or similar tools.")
    print("Example usage: collectl --import fefssv_v3 -s+Ljobstats -omdt,d")