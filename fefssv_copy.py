#!/usr/bin/env python3
import glob
import subprocess
import sys

UNUSED_MARK = "unused_mark"

DATA_TYPE_LIST = {
    "mdt": [
        "open", "close", "mknod", "link", "unlink", "mkdir", "rmdir",
        "rename", "getattr", "setattr", "getxattr", "setxattr", "statfs",
        "sync", "samedir_rename", "crossdir_rename"
    ],
    "ost": [
        "read", "read_bytes", "write", "write_bytes", "getattr", "setattr",
        "punch", "sync", "destroy", "create", "statfs", "get_info", "set_info",
        "quotactl"
    ]
}

class FEFSSVCopy:
    def __init__(self, options: str):
        # Options and mode
        self.mode = "summary"
        self.vol_type = UNUSED_MARK
        self.target_vol = UNUSED_MARK
        self.target_fs = UNUSED_MARK
        self.target_job = UNUSED_MARK
        self.fefs_ver = 2.6

        # Storage for data collection
        self.volname = UNUSED_MARK
        self.jobid = UNUSED_MARK
        self.target_vol_flg = 1
        self.target_job_flg = 1
        self.lj_data_out = {}
        self.lj_data_last = {}
        self.find_flg = {}

        self.options = options
        self.process_options()

    def error(self, msg: str):
        print(f"Error: {msg}", file=sys.stderr)
        sys.exit(1)

    @staticmethod
    def print_help():
        print("Usage: python fefssv_copy.py <options>")
        print("Options are comma-separated and include:")
        print("  d=<value>       Set mode to detail (can't be used with v).")
        print("  v=<value>       Set mode to verbose (can't be used with d).")
        print("  mdt=<value>     Set volume type to mdt and specify volume name.")
        print("  ost=<value>     Set volume type to ost and specify volume name.")
        print("  fs=<value>      Specify target filesystem. Incompatible with volume option.")
        print("  jobid=<value>   Specify target job id (requires mode verbose).")
        sys.exit(0)

    def process_options(self):
        for opt in self.options.split(','):
            try:
                name, value = opt.split('=')
            except ValueError:
                self.error(f"Option format error: {opt}")

            if name == 'd':
                if self.mode == 'verbose':
                    self.error("v and d options can't be used at the same time.")
                self.mode = "detail"
            elif name == 'v':
                if self.mode == 'detail':
                    self.error("v and d options can't be used at the same time.")
                self.mode = "verbose"
            elif name in ['mdt', 'ost']:
                if self.vol_type != UNUSED_MARK and self.vol_type != name:
                    self.error("mdt and ost options can't be used at the same time.")
                self.vol_type = name
                self.target_vol = f"/{value}/" if value else UNUSED_MARK
            elif name == 'fs':
                self.target_fs = f"/{value}/" if value else UNUSED_MARK
            elif name == 'jobid':
                self.target_job = f"/{value}/" if value else UNUSED_MARK
            else:
                self.error(f"Invalid option: {opt}")

        if self.vol_type == UNUSED_MARK:
            self.error("mdt or ost option is required if you print out the data.")
        if self.target_vol != UNUSED_MARK and self.target_fs != UNUSED_MARK:
            self.error("Can't specify a volume when you use fs option.")
        if self.target_fs != UNUSED_MARK and self.mode == 'summary':
            self.error("v or d option is required when you use fs option.")
        if self.target_vol != UNUSED_MARK and self.mode == 'summary':
            self.error("v or d option is required when you specify the volumes.")
        if self.target_job != UNUSED_MARK and self.mode != 'verbose':
            self.error("v option is required when you use jobid option.")

        self.check_fefs_version()

    def check_fefs_version(self):
        cmd = ["/bin/rpm", "-q", "FJSVfefs"]
        fefs_pkg = subprocess.getoutput(" ".join(cmd))
        if "FJSVfefs-1." in fefs_pkg:
            self.fefs_ver = 1.8
        else:
            self.fefs_ver = 2.6

    def init_interval(self):
        self.lj_data_out = {}
        self.find_flg = {}
        # Initialize the 'all'-'all' summary
        self.lj_data_out.setdefault('all', {}).setdefault('all', {})
        for dt in DATA_TYPE_LIST[self.vol_type]:
            self.lj_data_out['all']['all'][dt] = 0

    def get_data(self):
        mdt_paths = glob.glob("/proc/fs/lustre/md[ts]/*/job_stats")
        if mdt_paths:
            self.execute_command('/usr/sbin/lctl get_param md[ts].*.job_stats', f"Ljobstats-{self.vol_type}")

        ost_paths = glob.glob("/proc/fs/lustre/obdfilter/*/job_stats")
        if ost_paths:
            self.execute_command('/usr/sbin/lctl get_param obdfilter.*.job_stats', f"Ljobstats-{self.vol_type}")

    def execute_command(self, cmd: str, key: str):
        print(f"Command: {cmd}")
        result = subprocess.getoutput(cmd)
        self.analyze_data(key, result)

    def analyze_data(self, key: str, data: str):
        # Check if data type header matches expected key
        if key + ":" != f"Ljobstats-{self.vol_type}:":
            return

        parts = data.split(':')
        header = parts[0].strip()

        # Check for volume info
        if header.startswith(f"{self.vol_type}.") and header.endswith(".job_stats"):
            self.volname = header.split('.')[1]
            if self.target_fs != UNUSED_MARK:
                fs = self.volname.split('-')[0]
                self.target_vol_flg = 1 if f"/{fs}/" in self.target_fs else 0
            elif self.target_vol != UNUSED_MARK:
                self.target_vol_flg = 1 if f"/{self.volname}/" in self.target_vol else 0

            if self.target_vol_flg:
                self.lj_data_out.setdefault(self.volname, {}).setdefault('all', {})
                for dt in DATA_TYPE_LIST[self.vol_type]:
                    self.lj_data_out[self.volname]['all'][dt] = 0
        else:
            if not self.target_vol_flg:
                return

            if header == 'job_id':
                self.jobid = parts[1].strip()
                if self.target_job != UNUSED_MARK:
                    self.target_job_flg = 1 if f"/{self.jobid}/" in self.target_job else 0

                if self.target_job_flg:
                    self.find_flg.setdefault(self.volname, {})[self.jobid] = 1
                    self.lj_data_out.setdefault(self.volname, {}).setdefault(self.jobid, {})
                    for dt in DATA_TYPE_LIST[self.vol_type]:
                        self.lj_data_out[self.volname][self.jobid][dt] = 0
            else:
                if not self.target_job_flg:
                    return

                if header in ['read', 'read_bytes', 'write', 'write_bytes']:
                    # Expecting format: <header> samples:<samples>,sum:<sum_val>
                    try:
                        stats_part = data.split('samples:')[1]
                        samples_str, sum_str = stats_part.split(',', 1)
                        samples = int(samples_str)
                        sum_val = int(sum_str.split('sum:')[1])
                    except (IndexError, ValueError):
                        return

                    prev_stats = self.lj_data_last.get(self.volname, {}).get(self.jobid, {})
                    current = {}
                    if header in prev_stats:
                        current[header] = max(0, samples - prev_stats.get(header, 0))
                        key_bytes = f"{header}_bytes"
                        current[key_bytes] = max(0, sum_val - prev_stats.get(key_bytes, 0))
                    else:
                        current[header] = samples
                        current[f"{header}_bytes"] = sum_val

                    self.lj_data_out[self.volname][self.jobid].update(current)
                    self.lj_data_last.setdefault(self.volname, {}).setdefault(self.jobid, {})[header] = samples
                    self.lj_data_last[self.volname][self.jobid][f"{header}_bytes"] = sum_val

                    # Update summary for both the vol and all vols
                    self.lj_data_out[self.volname]['all'][header] = self.lj_data_out[self.volname]['all'].get(header, 0) + current[header]
                    key_bytes = f"{header}_bytes"
                    self.lj_data_out[self.volname]['all'][key_bytes] = self.lj_data_out[self.volname]['all'].get(key_bytes, 0) + current[key_bytes]

                    self.lj_data_out['all']['all'][header] += current[header]
                    self.lj_data_out['all']['all'][key_bytes] += current[key_bytes]
                else:
                    # For other data types that contain only samples
                    try:
                        samples = int(data.split('samples:')[1].split(',')[0])
                    except (IndexError, ValueError):
                        return

                    prev_samples = self.lj_data_last.get(self.volname, {}).get(self.jobid, {}).get(header, 0)
                    diff = max(0, samples - prev_samples)
                    self.lj_data_out[self.volname][self.jobid][header] = diff
                    self.lj_data_last.setdefault(self.volname, {}).setdefault(self.jobid, {})[header] = samples

                    self.lj_data_out[self.volname]['all'][header] = self.lj_data_out[self.volname]['all'].get(header, 0) + diff
                    self.lj_data_out['all']['all'][header] += diff

    def interval_end(self):
        # Remove stale jobid entries
        for vol in list(self.lj_data_last.keys()):
            for job in list(self.lj_data_last[vol].keys()):
                if job not in self.find_flg.get(vol, {}):
                    del self.lj_data_last[vol][job]

    def print_brief(self):
        lines = []
        lines.append(self.headline())
        lines.append(self.subheadline())
        lines.append(self.summary_line())
        return lines

    def headline(self):
        if self.vol_type == 'mdt':
            if self.fefs_ver == 2.6:
                return "<----------------------------------------------------------------------Lustre Jobstats----------------------------------------------------------------------->"
            else:
                return "<------------------------------------------------------Lustre Jobstats------------------------------------------------------->"
        else:
            if self.fefs_ver == 2.6:
                return "<------------------------------------------------------------Lustre Jobstats------------------------------------------------------------->"
            else:
                return "<-----------------------------Lustre Jobstats----------------------------->"

    def subheadline(self):
        if self.vol_type == 'mdt':
            if self.fefs_ver == 2.6:
                return ("    open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr "
                        "getxattr setxattr   statfs     sync  samedir_rename crossdir_rename ")
            else:
                return ("    open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr "
                        "getxattr setxattr   statfs     sync ")
        else:
            if self.fefs_ver == 2.6:
                return ("    read  read_bytes[B]    write write_bytes[B]  getattr  setattr    punch     sync  destroy   create   "
                        "statfs get_info set_info quotactl ")
            else:
                return ("    read  read_bytes[B]    write write_bytes[B]  setattr    punch     sync ")

    def summary_line(self):
        all_stats = self.lj_data_out['all']['all']
        if self.vol_type == 'mdt':
            if self.fefs_ver == 2.6:
                return (f"{all_stats.get('open', 0):8} {all_stats.get('close', 0):8} {all_stats.get('mknod', 0):8} "
                        f"{all_stats.get('link', 0):8} {all_stats.get('unlink', 0):8} {all_stats.get('mkdir', 0):8} "
                        f"{all_stats.get('rmdir', 0):8} {all_stats.get('rename', 0):8} {all_stats.get('getattr', 0):8} "
                        f"{all_stats.get('setattr', 0):8} {all_stats.get('getxattr', 0):8} {all_stats.get('setxattr', 0):8} "
                        f"{all_stats.get('statfs', 0):8} {all_stats.get('sync', 0):8} {all_stats.get('samedir_rename', 0):15} "
                        f"{all_stats.get('crossdir_rename', 0):15}")
            else:
                return (f"{all_stats.get('open', 0):8} {all_stats.get('close', 0):8} {all_stats.get('mknod', 0):8} "
                        f"{all_stats.get('link', 0):8} {all_stats.get('unlink', 0):8} {all_stats.get('mkdir', 0):8} "
                        f"{all_stats.get('rmdir', 0):8} {all_stats.get('rename', 0):8} {all_stats.get('getattr', 0):8} "
                        f"{all_stats.get('setattr', 0):8} {all_stats.get('getxattr', 0):8} {all_stats.get('setxattr', 0):8} "
                        f"{all_stats.get('statfs', 0):8} {all_stats.get('sync', 0):8}")
        else:
            if self.fefs_ver == 2.6:
                return (f"{all_stats.get('read', 0):8} {all_stats.get('read_bytes', 0):14} {all_stats.get('write', 0):8} "
                        f"{all_stats.get('write_bytes', 0):14} {all_stats.get('getattr', 0):8} {all_stats.get('setattr', 0):8} "
                        f"{all_stats.get('punch', 0):8} {all_stats.get('sync', 0):8} {all_stats.get('destroy', 0):8} "
                        f"{all_stats.get('create', 0):8} {all_stats.get('statfs', 0):8} {all_stats.get('get_info', 0):8} "
                        f"{all_stats.get('set_info', 0):8} {all_stats.get('quotactl', 0):8}")
            else:
                return (f"{all_stats.get('read', 0):8} {all_stats.get('read_bytes', 0):14} {all_stats.get('write', 0):8} "
                        f"{all_stats.get('write_bytes', 0):14} {all_stats.get('setattr', 0):8} {all_stats.get('punch', 0):8} "
                        f"{all_stats.get('sync', 0):8}")

    def run(self):
        self.init_interval()
        self.get_data()
        self.interval_end()
        for line in self.print_brief():
            print(line)


def main():
    if len(sys.argv) < 2:
        print("Usage: python fefssv_copy.py <options> (use -h for help)", file=sys.stderr)
        sys.exit(1)

    if any(arg in ['-h', '--help'] for arg in sys.argv):
        FEFSSVCopy.print_help()

    options = sys.argv[1]
    fsv_copy = FEFSSVCopy(options)
    fsv_copy.run()


if __name__ == "__main__":
    main()