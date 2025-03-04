#!/usr/bin/env python3
"""
fefssv_v2.py - Pythonic implementation of Lustre Jobstats data collection.
"""

import re
import glob
import subprocess
import time
import sys
import argparse
from datetime import datetime


class Fefssv:
    def __init__(self, mode, vol_type, target_vol, target_fs, target_job):
        self.mode = mode              # "summary", "detail", or "verbose"
        self.vol_type = vol_type      # "mdt" or "ost"
        self.target_vol = target_vol  # e.g., "/value/"
        self.target_fs = target_fs    # e.g., "/value/"
        self.target_job = target_job  # e.g., "/value/" (used in verbose mode)
        self.fefs_ver = 2.6
        self.lj_data_out = {"all": {"all": {}}}
        self.lj_data_last = {}
        self.find_flg = {}

    def error(self, msg):
        raise ValueError(msg)

    def get_exec(self, command, identifier=""):
        try:
            output = subprocess.check_output(command.split(), stderr=subprocess.STDOUT,
                                             universal_newlines=True)
            # For debugging: print(f"{identifier}: {output}")
            return output
        except subprocess.CalledProcessError as e:
            self.error(f"Command '{command}' failed: {e.output}")

    def init_fefs_version(self):
        pkg_cmd = "/bin/rpm -q FJSVfefs"
        try:
            out = self.get_exec(pkg_cmd, "rpm")
            if re.search(r"FJSVfefs-1\.[0-9]\.[0-9]-", out):
                self.fefs_ver = 1.8
            else:
                self.fefs_ver = 2.6
        except Exception:
            self.fefs_ver = 2.6

    def get_data_types(self):
        types = {
            "mdt": ["open", "close", "mknod", "link", "unlink", "mkdir", "rmdir", "rename",
                    "getattr", "setattr", "getxattr", "setxattr", "statfs", "sync",
                    "samedir_rename", "crossdir_rename"],
            "ost": ["read", "read_bytes", "write", "write_bytes", "getattr", "setattr",
                    "punch", "sync", "destroy", "create", "statfs", "get_info", "set_info", "quotactl"]
        }
        return types.get(self.vol_type, [])

    def init_interval(self):
        self.lj_data_out = {"all": {"all": {}}}
        for dt in self.get_data_types():
            self.lj_data_out["all"]["all"][dt] = 0
        self.lj_data_last = {}
        self.find_flg = {}

    def get_data(self):
        # Query Lustre job_stats.
        mdt_paths = glob.glob("/proc/fs/lustre/md[ts]/*/job_stats")
        if mdt_paths:
            self.get_exec("/usr/sbin/lctl get_param md[ts].*.job_stats", "Ljobstats-mdt")
        ost_paths = glob.glob("/proc/fs/lustre/obdfilter/*/job_stats")
        if ost_paths:
            self.get_exec("/usr/sbin/lctl get_param obdfilter.*.job_stats", "Ljobstats-ost")

    def analyze_line(self, label, data):
        """
        Analyze a data line from Lustre stats.
        'label' should be of the form "Ljobstats-<vol_type>:".
        """
        if label != f"Ljobstats-{self.vol_type}:":
            return

        m = re.match(r"^[\-\s]*(\S+)[:=]", data)
        if not m:
            return
        dt = m.group(1)

        # Check for volume header indicating volume name.
        vol_match = re.search(r"\S+\.(\S+\-\S+)\.job_stats", dt)
        if vol_match:
            volname = vol_match.group(1)
            # Filter based on target_fs or target_vol if provided.
            if self.target_fs:
                m_fs = re.match(r"^(\S+)\-\S+", volname)
                if m_fs and f"/{m_fs.group(1)}/" not in self.target_fs:
                    return
            elif self.target_vol:
                if volname not in self.target_vol:
                    return
            # Initialize data structure.
            self.lj_data_out.setdefault(volname, {}).setdefault("all", {})
            for dt_field in self.get_data_types():
                self.lj_data_out[volname]["all"].setdefault(dt_field, 0)
        else:
            # Process job ID or counter lines.
            if dt == "job_id":
                m_job = re.search(r"job_id:\s*(\S+)", data)
                if m_job:
                    jobid = m_job.group(1)
                    if self.target_job and (jobid not in self.target_job):
                        return
                    self.find_flg.setdefault(volname, {})[jobid] = True
                    self.lj_data_out.setdefault(volname, {}).setdefault(jobid, {})
                    for dt_field in self.get_data_types():
                        self.lj_data_out[volname][jobid].setdefault(dt_field, 0)
            else:
                # Simplified counter extraction.
                if dt in ["read", "read_bytes", "write", "write_bytes"]:
                    m_vals = re.search(r"samples:\s*(\d+),.*sum:\s*(\d+)", data)
                    if m_vals:
                        value = int(m_vals.group(1))
                        self.lj_data_out[volname][jobid][dt] = value
                elif dt not in ["job_stats", "snapshot_time"]:
                    m_vals = re.search(r"samples:\s*(\d+)", data)
                    if m_vals:
                        count = int(m_vals.group(1))
                        self.lj_data_out[volname][jobid][dt] = count

    def interval_end(self):
        # Remove job entries not marked as found.
        for vol in list(self.lj_data_last.keys()):
            for job in list(self.lj_data_last[vol].keys()):
                if vol not in self.find_flg or job not in self.find_flg[vol]:
                    del self.lj_data_last[vol][job]

    def get_datetime_str(self):
        return datetime.now().strftime("\n%Y%m%d %H:%M:%S")

    def update_header(self):
        hdr = "# FEFS:       "
        hdr += "Lustre 1.8 base" if self.fefs_ver == 1.8 else "Lustre 2.6 base"
        return hdr

    def print_brief(self):
        header = self.update_header()
        dt_line = self.get_datetime_str()
        brief = f"Jobstats for {self.vol_type.upper()} - Mode: {self.mode}"
        return f"{header}\n{dt_line}\n{brief}"


def parse_args():
    parser = argparse.ArgumentParser(
        description="Lustre Jobstats data collection tool (Pythonic v2)",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("-d", action="store_true", help="Set detail mode")
    parser.add_argument("-v", action="store_true", help="Set verbose mode")
    parser.add_argument("--mdt", type=str, help="Specify mdt volume")
    parser.add_argument("--ost", type=str, help="Specify ost volume")
    parser.add_argument("--fs", type=str, help="Specify filesystem")
    parser.add_argument("--jobid", type=str, help="Specify job ID (requires verbose mode)")
    return parser.parse_args()


def main():
    args = parse_args()

    # Determine mode.
    if args.v:
        mode = "verbose"
    elif args.d:
        mode = "detail"
    else:
        mode = "summary"

    # Determine volume type.
    if args.mdt:
        vol_type = "mdt"
        target_vol = f"/{args.mdt}/"
    elif args.ost:
        vol_type = "ost"
        target_vol = f"/{args.ost}/"
    else:
        sys.stderr.write("Error: You must specify either --mdt or --ost option.\n")
        sys.exit(1)

    target_fs = f"/{args.fs}/" if args.fs else ""
    target_job = f"/{args.jobid}/" if args.jobid else ""

    fef = Fefssv(mode, vol_type, target_vol, target_fs, target_job)
    fef.init_fefs_version()
    fef.init_interval()
    fef.get_data()

    # For demonstration, process a sample line.
    sample_line = "job_id: 12345"
    fef.analyze_line(f"Ljobstats-{fef.vol_type}:", sample_line)
    # End interval step (if applicable)
    fef.interval_end()

    print(fef.print_brief())


if __name__ == "__main__":
    main()
