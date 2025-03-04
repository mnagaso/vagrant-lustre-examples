#!/usr/bin/env python3
import re
import glob
import subprocess
import time
import os
import sys
from datetime import datetime

# Global Variables
miniFiller = ""
SEP = " "  # Separator (adjust as needed)
datetime_str = ""
showColFlag = False
options = ""      # Options string (set externally as needed)
filename = ""     # The filename to use elsewhere
plotFlag = False

lastSeconds = []  # list of timestamps
rawPFlag = 0
intSeconds = int(time.time())
intUsecs = 0
utcFlag = False
hiResFlag = False

lj_data_out = {}
lj_data_last = {}
find_flg = {}
data_type_list = {
    "mdt": ["open", "close", "mknod", "link", "unlink", "mkdir", "rmdir", "rename",
            "getattr", "setattr", "getxattr", "setxattr", "statfs", "sync",
            "samedir_rename", "crossdir_rename"],
    "ost": ["read", "read_bytes", "write", "write_bytes", "getattr", "setattr",
            "punch", "sync", "destroy", "create", "statfs", "get_info", "set_info", "quotactl"]
}
UNUSED_MARK = "unused_mark"
volname = UNUSED_MARK
jobid = UNUSED_MARK
target_fs = UNUSED_MARK
target_vol = UNUSED_MARK
target_job = UNUSED_MARK
vol_type = UNUSED_MARK
mode = "summary"
target_vol_flg = True
target_job_flg = True
fefs_ver = 2.6  # default fefs version

def error(msg):
    raise Exception(msg)

def getExec(flag, command, identifier):
    """
    Execute a command. In a real system this might log or process output.
    For now, simply run the command if flag==0.
    """
    try:
        output = subprocess.check_output(command.split(), stderr=subprocess.STDOUT, universal_newlines=True)
        # Debug: print(f"{identifier}: {output}")
    except subprocess.CalledProcessError as e:
        error(f"Command '{command}' failed: {e.output}")

def fefssvInit(impOpts, impKey):
    """
    Initialize with options.
    impOpts: list with one string element for options.
    impKey: list with one string element for key.
    """
    global mode, vol_type, target_vol, target_fs, target_job, fefs_ver
    PKG_NAME = "FJSVfefs"
    CMD = f"/bin/rpm -q {PKG_NAME}"

    if impOpts[0]:
        opts = impOpts[0].split(',')
        for opt in opts:
            parts = opt.split('=')
            name = parts[0]
            value = parts[1] if len(parts) > 1 else None

            if name == 'd':
                if mode == 'verbose':
                    error("fefssv: v and d options can't be used at the same time.")
                mode = "detail"
            elif name == 'v':
                if mode == 'detail':
                    error("fefssv: v and d options can't be used at the same time.")
                mode = "verbose"
            elif name == 'mdt':
                if vol_type == 'ost':
                    error("fefssv: mdt and ost options can't be used at the same time.")
                vol_type = "mdt"
                if value:
                    target_vol = f"/{value}/"
            elif name == 'ost':
                if vol_type == 'mdt':
                    error("fefssv: mdt and ost options can't be used at the same time.")
                vol_type = "ost"
                if value:
                    target_vol = f"/{value}/"
            elif name == 'fs':
                if value:
                    target_fs = f"/{value}/"
            elif name == 'jobid':
                if value:
                    target_job = f"/{value}/"
            else:
                error(f"fefssv: invalid option: {opt}")

    # Check required options
    if (not filename and not plotFlag) and vol_type == UNUSED_MARK:
        error("fefssv: mdt or ost option is required if you print out the data.")
    if target_vol != UNUSED_MARK and target_fs != UNUSED_MARK:
        error("fefssv: can't specify a volume when you use fs option.")
    if target_fs != UNUSED_MARK and mode == "summary":
        error("fefssv: v or d option is required when you use fs option.")
    if target_vol != UNUSED_MARK and mode == "summary":
        error("fefssv: v or d option is required when you specify the volumes.")
    if target_job != UNUSED_MARK and mode != "verbose":
        error("fefssv: v option is required when you use jobid option.")

    # Set return option
    if mode == "summary":
        impOpts[0] = "s"
    else:
        impOpts[0] = "d"

    # Check fefs version using rpm command
    try:
        fefs_pkg = subprocess.check_output(CMD.split(), stderr=subprocess.STDOUT, universal_newlines=True)
    except subprocess.CalledProcessError:
        fefs_pkg = ""
    if re.search(r"FJSVfefs-1\.[0-9]\.[0-9]-", fefs_pkg):
        fefs_ver = 1.8
    else:
        fefs_ver = 2.6

    impKey[0] = "Ljobstats"
    return 1

def fefssvInitInterval():
    global lj_data_out, find_flg
    lj_data_out = {}
    find_flg = {}
    for dt in data_type_list.get(vol_type, []):
        lj_data_out.setdefault("all", {}).setdefault("all", {})[dt] = 0

def fefssvGetData():
    mdt_paths = glob.glob("/proc/fs/lustre/md[ts]/*/job_stats")
    if mdt_paths:
        getExec(0, "/usr/sbin/lctl get_param md[ts].*.job_stats", "Ljobstats-mdt")
    ost_paths = glob.glob("/proc/fs/lustre/obdfilter/*/job_stats")
    if ost_paths:
        getExec(0, "/usr/sbin/lctl get_param obdfilter.*.job_stats", "Ljobstats-ost")

def fefssvAnalyze(data_type, data):
    global volname, target_vol_flg, target_job_flg
    if data_type != f"Ljobstats-{vol_type}:":
        return

    m = re.match(r"^[\-\s]*(\S+)[:=]", data)
    if not m:
        return
    dt = m.group(1)

    vol_m = re.search(r"\S+\.(\S+\-\S+)\.job_stats", dt)
    if vol_m:
        volname = vol_m.group(1)
        if target_fs != UNUSED_MARK:
            m_fs = re.match(r"^(\S+)\-\S+", volname)
            if m_fs:
                fs = m_fs.group(1)
                target_vol_flg = True if re.search(f"/{fs}/", target_fs) else False
        elif target_vol != UNUSED_MARK:
            target_vol_flg = True if re.search(re.escape(volname), target_vol) else False
        if target_vol_flg:
            lj_data_out.setdefault(volname, {}).setdefault("all", {})
            for dt in data_type_list.get(vol_type, []):
                lj_data_out[volname]["all"].setdefault(dt, 0)
    else:
        if not target_vol_flg:
            return
        if dt == "job_id":
            m_job = re.search(r"job_id:\s*(\S+)", data)
            if m_job:
                local_jobid = m_job.group(1)
                global jobid
                jobid = local_jobid
                if target_job != UNUSED_MARK:
                    target_job_flg = True if re.search(re.escape(jobid), target_job) else False
                if target_job_flg:
                    find_flg.setdefault(volname, {})[jobid] = True
                    lj_data_out.setdefault(volname, {}).setdefault(jobid, {})
                    for dt_field in data_type_list.get(vol_type, []):
                        lj_data_out[volname][jobid].setdefault(dt_field, 0)
        else:
            if not target_job_flg:
                return
            if dt in ["read", "read_bytes"]:
                m_vals = re.search(r"samples:\s*(\d+),.*sum:\s*(\d+)", data)
                if m_vals:
                    read_val = int(m_vals.group(1))
                    read_bytes_val = int(m_vals.group(2))
                    prev_read = lj_data_last.get(volname, {}).get(jobid, {}).get("read", None)
                    if prev_read is not None:
                        diff_read = read_val - prev_read if read_val >= prev_read else read_val
                        diff_read_bytes = read_bytes_val - lj_data_last.get(volname, {}).get(jobid, {}).get("read_bytes", 0)
                    else:
                        diff_read = read_val
                        diff_read_bytes = read_bytes_val
                    lj_data_out[volname][jobid]["read"] = diff_read
                    lj_data_out[volname][jobid]["read_bytes"] = diff_read_bytes
                    lj_data_last.setdefault(volname, {}).setdefault(jobid, {})["read"] = read_val
                    lj_data_last[volname][jobid]["read_bytes"] = read_bytes_val
                    lj_data_out["all"]["all"]["read"] = lj_data_out["all"]["all"].get("read", 0) + diff_read
                    lj_data_out["all"]["all"]["read_bytes"] = lj_data_out["all"]["all"].get("read_bytes", 0) + diff_read_bytes
            elif dt in ["write", "write_bytes"]:
                m_vals = re.search(r"samples:\s*(\d+),.*sum:\s*(\d+)", data)
                if m_vals:
                    write_val = int(m_vals.group(1))
                    write_bytes_val = int(m_vals.group(2))
                    prev_write = lj_data_last.get(volname, {}).get(jobid, {}).get("write", None)
                    if prev_write is not None:
                        diff_write = write_val - prev_write if write_val >= prev_write else write_val
                        diff_write_bytes = write_bytes_val - lj_data_last.get(volname, {}).get(jobid, {}).get("write_bytes", 0)
                    else:
                        diff_write = write_val
                        diff_write_bytes = write_bytes_val
                    lj_data_out[volname][jobid]["write"] = diff_write
                    lj_data_out[volname][jobid]["write_bytes"] = diff_write_bytes
                    lj_data_last.setdefault(volname, {}).setdefault(jobid, {})["write"] = write_val
                    lj_data_last[volname][jobid]["write_bytes"] = write_bytes_val
                    lj_data_out[volname]["all"]["write"] = lj_data_out[volname]["all"].get("write", 0) + diff_write
                    lj_data_out[volname]["all"]["write_bytes"] = lj_data_out[volname]["all"].get("write_bytes", 0) + diff_write_bytes
                    lj_data_out["all"]["all"]["write"] = lj_data_out["all"]["all"].get("write", 0) + diff_write
                    lj_data_out["all"]["all"]["write_bytes"] = lj_data_out["all"]["all"].get("write_bytes", 0) + diff_write_bytes
            elif dt not in ["job_stats", "snapshot_time"]:
                m_vals = re.search(r"samples:\s*(\d+)", data)
                if m_vals:
                    exec_cnt = int(m_vals.group(1))
                    prev = lj_data_last.get(volname, {}).get(jobid, {}).get(dt, None)
                    diff = exec_cnt - prev if prev is not None and exec_cnt >= prev else exec_cnt
                    lj_data_out[volname][jobid][dt] = diff
                    lj_data_last.setdefault(volname, {}).setdefault(jobid, {})[dt] = exec_cnt
                    lj_data_out[volname]["all"][dt] = lj_data_out[volname]["all"].get(dt, 0) + diff
                    lj_data_out["all"]["all"][dt] = lj_data_out["all"]["all"].get(dt, 0) + diff

def fefssvIntervalEnd():
    for vol in list(lj_data_last.keys()):
        for job in list(lj_data_last[vol].keys()):
            if vol not in find_flg or job not in find_flg[vol]:
                del lj_data_last[vol][job]

def make_datetime(current_seconds=None):
    global datetime_str
    if current_seconds is None:
        current_seconds = int(time.time())
    dt_obj = datetime.fromtimestamp(current_seconds)
    datetime_str = dt_obj.strftime("\n%Y%m%d %H:%M:%S")
    return datetime_str

def fefssvPrintBrief(print_type):
    line = ""
    if print_type == 1:
        if vol_type == "mdt":
            if fefs_ver == 2.6:
                line += "<----------------------------------------------------------------------Lustre Jobstats----------------------------------------------------------------------->"
            else:
                line += "<------------------------------------------------------Lustre Jobstats------------------------------------------------------->"
        else:
            if fefs_ver == 2.6:
                line += "<------------------------------------------------------------Lustre Jobstats------------------------------------------------------------->"
            else:
                line += "<-----------------------------Lustre Jobstats----------------------------->"
    elif print_type == 2:
        if vol_type == "mdt":
            if fefs_ver == 2.6:
                line += "    open    close   mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync  samedir_rename crossdir_rename"
            else:
                line += "    open    close   mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync"
        else:
            if fefs_ver == 2.6:
                line += "    read  read_bytes[B]    write write_bytes[B]  getattr  setattr    punch     sync  destroy   create   statfs get_info set_info quotactl"
            else:
                line += "    read  read_bytes[B]    write write_bytes[B]  setattr    punch     sync"
    elif print_type == 3:
        if vol_type == "mdt":
            if fefs_ver == 2.6:
                line += "{:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:15d} {:15d}".format(
                    lj_data_out["all"]["all"].get("open",0),
                    lj_data_out["all"]["all"].get("close",0),
                    lj_data_out["all"]["all"].get("mknod",0),
                    lj_data_out["all"]["all"].get("link",0),
                    lj_data_out["all"]["all"].get("unlink",0),
                    lj_data_out["all"]["all"].get("mkdir",0),
                    lj_data_out["all"]["all"].get("rmdir",0),
                    lj_data_out["all"]["all"].get("rename",0),
                    lj_data_out["all"]["all"].get("getattr",0),
                    lj_data_out["all"]["all"].get("setattr",0),
                    lj_data_out["all"]["all"].get("getxattr",0),
                    lj_data_out["all"]["all"].get("setxattr",0),
                    lj_data_out["all"]["all"].get("statfs",0),
                    lj_data_out["all"]["all"].get("sync",0),
                    lj_data_out["all"]["all"].get("samedir_rename",0),
                    lj_data_out["all"]["all"].get("crossdir_rename",0)
                )
            else:
                line += "{:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d} {:8d}".format(
                    lj_data_out["all"]["all"].get("open",0),
                    lj_data_out["all"]["all"].get("close",0),
                    lj_data_out["all"]["all"].get("mknod",0),
                    lj_data_out["all"]["all"].get("link",0),
                    lj_data_out["all"]["all"].get("unlink",0),
                    lj_data_out["all"]["all"].get("mkdir",0),
                    lj_data_out["all"]["all"].get("rmdir",0),
                    lj_data_out["all"]["all"].get("rename",0),
                    lj_data_out["all"]["all"].get("getattr",0),
                    lj_data_out["all"]["all"].get("setattr",0),
                    lj_data_out["all"]["all"].get("getxattr",0),
                    lj_data_out["all"]["all"].get("setxattr",0),
                    lj_data_out["all"]["all"].get("statfs",0),
                    lj_data_out["all"]["all"].get("sync",0)
                )
        else:
            if fefs_ver == 2.6:
                line += "{:8d} {:14d} {:8d} {:14d} {:8d} {:8d} ...".format(
                    lj_data_out["all"]["all"].get("read",0),
                    lj_data_out["all"]["all"].get("read_bytes",0),
                    lj_data_out["all"]["all"].get("write",0),
                    lj_data_out["all"]["all"].get("write_bytes",0),
                    lj_data_out["all"]["all"].get("getattr",0),
                    lj_data_out["all"]["all"].get("setattr",0)
                )
            else:
                line += "{:8d} {:14d} {:8d} {:14d} {:8d} {:8d} ...".format(
                    lj_data_out["all"]["all"].get("read",0),
                    lj_data_out["all"]["all"].get("read_bytes",0),
                    lj_data_out["all"]["all"].get("write",0),
                    lj_data_out["all"]["all"].get("write_bytes",0),
                    lj_data_out["all"]["all"].get("setattr",0),
                    lj_data_out["all"]["all"].get("punch",0)
                )
    return line

def fefssvUpdateHeader():
    hdr = "# FEFS:       "
    if fefs_ver == 1.8:
        hdr += "Lustre 1.8 base\n"
    else:
        hdr += "Lustre 2.6 base\n"
    return hdr

def fefssvGetHeader(data):
    global fefs_ver
    if "Lustre 1.8 base" in data:
        fefs_ver = 1.8
    else:
        fefs_ver = 2.6

def fefssvPrintExport():
    pass

def print_help():
    help_msg = (
        "Usage: fefssv.py [options]\n"
        "Options:\n"
        "  -h, --help           Show this help message and exit\n"
        "  -d                   Set detail mode\n"
        "  -v                   Set verbose mode\n"
        "  mdt=<value>         Specify mdt volume\n"
        "  ost=<value>         Specify ost volume\n"
        "  fs=<value>          Specify filesystem\n"
        "  jobid=<value>       Specify job ID (requires verbose mode)\n"
    )
    print(help_msg)

if __name__ == "__main__":
    # Help option handling
    if "-h" in sys.argv or "--help" in sys.argv:
        print_help()
        sys.exit(0)

    # For demonstration, assume options and key are provided as list wrappers.
    # Here, options can be passed as command-line arguments without flags.
    opts = [""]
    key = [""]
    # Simple parsing: combine non-help arguments into an option string.
    non_help_args = [arg for arg in sys.argv[1:] if arg not in ("-h", "--help")]
    if non_help_args:
        opts[0] = ",".join(non_help_args)
    try:
        fefssvInit(opts, key)
    except Exception as e:
        print(f"Initialization error: {e}")
        sys.exit(1)

    fefssvInitInterval()
    fefssvGetData()
    # For demonstration, process a sample data line.
    sample_line = "job_id: 12345"
    fefssvAnalyze(f"Ljobstats-{vol_type}:", sample_line)
    fefssvIntervalEnd()
    header = fefssvUpdateHeader()
    dt_line = make_datetime()
    brief = fefssvPrintBrief(1)
    print(header)
    print(dt_line)
    print(brief)
