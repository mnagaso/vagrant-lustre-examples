######################################################################
#                                                                    #
# fefssv - Lustre Jobstats data collect script                       #
#                                                                    #
######################################################################
#                                                                    #
# Description:                                                       #
#   This script collect the data for Lustre Jobstats.                #
#                                                                    #
# Copyright(c) 2015,2018 FUJITSU LIMITED.                                 #
# All rights reserved.                                               #
######################################################################

use strict;

# Allow reference to collectl variables, but be CAREFUL as these should be treated as readonly
our ($miniFiller, $SEP, $datetime, $showColFlag, $options, $filename, $plotFlag);
our (@lastSeconds, $rawPFlag, $intSeconds, $intUsecs, $utcFlag, $hiResFlag);


my (%lj_data_out, %lj_data_last, %find_flg, %data_type_list);
my $UNUSED_MARK="unused_mark";
my $volname=$UNUSED_MARK;
my $jobid=$UNUSED_MARK;
my $target_fs=$UNUSED_MARK;
my $target_vol=$UNUSED_MARK;
my $target_job=$UNUSED_MARK;
my $vol_type=$UNUSED_MARK;
my $mode="summary";
my $target_vol_flg=1;
my $target_job_flg=1;
my $fefs_ver=2.6;

@{$data_type_list{mdt}}=("open", "close", "mknod", "link", "unlink", "mkdir", "rmdir", "rename", "getattr", "setattr", "getxattr", "setxattr", "statfs", "sync", "samedir_rename", "crossdir_rename");
@{$data_type_list{ost}}=("read", "read_bytes", "write", "write_bytes", "getattr", "setattr", "punch", "sync", "destroy", "create", "statfs", "get_info", "set_info", "quotactl");


sub fefssvInit
{
  my $impOptsref=shift;
  my $impKeyref=shift;

  my $PKG_NAME="FJSVfefs";
  my $CMD="/bin/rpm -q $PKG_NAME 2>&1";

  # check options.
  if (defined($$impOptsref))
  {
    foreach my $opt (split(/,/,$$impOptsref))
    {
      my ($name, $value)=split(/=/,$opt);

      if ($name eq 'd')
      {
        error("fefssv : v and d options can't be used in the same time.")  if $mode eq 'verbose';
        $mode="detail";
      }
      elsif ($name eq 'v')
      {
        error("fefssv : v and d options can't be used in the same time.")  if $mode eq 'detail';
        $mode="verbose";
      }
      elsif ($name eq 'mdt')
      {
        error("fefssv : mdt and ost options can't be used in the same time.")  if $vol_type eq 'ost';
        $vol_type="mdt";
        $target_vol="/$value/"  if defined($value);
      }
      elsif ($name eq 'ost')
      {
        error("fefssv : mdt and ost options can't be used in the same time.")  if $vol_type eq 'mdt';
        $vol_type="ost";
        $target_vol="/$value/"  if defined($value);
      }
      elsif ($name eq 'fs')
      {
        $target_fs="/$value/"  if defined($value);
      }
      elsif ($name eq 'jobid')
      {
        $target_job="/$value/"  if defined($value);
      }
      else
      {
        error("fefssv : invalid option : $opt");
      }
    }
  }

  error("fefssv : mdt or ost option is required if you print out the data.")  if !($filename ne '' && !$plotFlag) && $vol_type eq $UNUSED_MARK;
  error("fefssv : can't specify a volume when you use fs option.")  if $target_vol ne $UNUSED_MARK && $target_fs ne $UNUSED_MARK;
  error("fefssv : v or d option is required when you use fs option.")  if $target_fs ne $UNUSED_MARK && $mode eq 'summary';
  error("fefssv : v or d option is required when you specify the volumes.")  if $target_vol ne $UNUSED_MARK && $mode eq 'summary';
  error("fefssv : v option is required when you use jobid option.")  if $target_job ne $UNUSED_MARK && $mode ne 'verbose';

  # set return option.
  if ($mode eq 'summary')
  {
    $$impOptsref="s";
  }
  else
  {
    $$impOptsref="d";
  }

  #check fefs version.
  my $fefs_pkg=`$CMD`;
  if ($fefs_pkg=~/FJSVfefs-1\.[0-9]\.[0-9]-/)
  {
    $fefs_ver=1.8;
  }
  else
  {
    $fefs_ver=2.6;
  }

  # set fefssv key.
  $$impKeyref='Ljobstats';
  return(1);

}


sub fefssvInitInterval
{
  # reset output data.
  %lj_data_out=();
  undef(%lj_data_out);

  # reset find flag.
  %find_flg=();
  undef(%find_flg);

  foreach my $dt (@{$data_type_list{$vol_type}})
  {
    $lj_data_out{all}{all}{$dt}=0;
  }
}


sub fefssvGetData
{
  my @mnt_check;
  # get mdt jobstats data.
  @mnt_check=glob("/proc/fs/lustre/md[ts]/*/job_stats");
  getExec(0,'/usr/sbin/lctl get_param md[ts].*.job_stats','Ljobstats-mdt')  if "@mnt_check" ne "";

  # get ost jobstats data.
  @mnt_check=glob("/proc/fs/lustre/obdfilter/*/job_stats");
  getExec(0,'/usr/sbin/lctl get_param obdfilter.*.job_stats','Ljobstats-ost') if "@mnt_check" ne "";
}

sub fefssvAnalyze
{
  my $type=shift;
  my $data=shift;

  return if "$type" ne "Ljobstats-${vol_type}:";

  $$data=~/^[\-\s]*(\S+)[:=]/;
  my $data_type=$1;

  # analyze Jobstats data.
  if ($data_type=~/^\S+\.(\S+\-\S+)\.job_stats/)
  {
    $volname=$1;

    if ($target_fs ne $UNUSED_MARK)
    {
      $volname=~/^(\S+)\-\S+/;
      my $fs=$1;
      if ($target_fs=~/\/$fs\//)
      {
        $target_vol_flg=1;
      }
      else
      {
        $target_vol_flg=0;
      }
    }
    elsif ($target_vol ne $UNUSED_MARK)
    {
      if ($target_vol=~/\/$volname\//)
      {
        $target_vol_flg=1;
      }
      else
      {
        $target_vol_flg=0;
      }
    }
    if ($target_vol_flg==1)
    {
      foreach my $dt (@{$data_type_list{$vol_type}})
      {
        $lj_data_out{$volname}{all}{$dt}=0;
      }
    }
  }
  else
  {
    return if $target_vol_flg==0;

    if ($data_type eq 'job_id')
    {
      $$data=~/job_id:\s*(\S+)/;
      $jobid=$1;

      if ($target_job ne $UNUSED_MARK)
      {
        if ($target_job=~/\/\Q$jobid\E\//)
        {
          $target_job_flg=1;
        }
        else
        {
          $target_job_flg=0;
        }
      }
      if ($target_job_flg==1)
      {
        $find_flg{$volname}{$jobid}=1;
        foreach my $dt (@{$data_type_list{$vol_type}})
        {
          $lj_data_out{$volname}{$jobid}{$dt}=0;
        }
      }
    }
    else
    {
      return if $target_job_flg==0;

      if  ($data_type eq 'read' || $data_type eq 'read_bytes')
      {
        $$data=~/samples:\s*(\d+),.*sum:\s*(\d+)\s\}/;
        my $read=$1;
        my $read_bytes=$2;

        if (defined($lj_data_last{$volname}{$jobid}{$data_type}))
        {
          $lj_data_out{$volname}{$jobid}{read}=$read>=$lj_data_last{$volname}{$jobid}{read}?
                     $read-$lj_data_last{$volname}{$jobid}{read}:$read;
          $lj_data_out{$volname}{$jobid}{read_bytes}=$read_bytes>=$lj_data_last{$volname}{$jobid}{read_bytes}?
                     $read_bytes-$lj_data_last{$volname}{$jobid}{read_bytes}:$read_bytes;
        }
        else
        {
          $lj_data_out{$volname}{$jobid}{read}=$read;
          $lj_data_out{$volname}{$jobid}{read_bytes}=$read_bytes;
        }
        $lj_data_last{$volname}{$jobid}{read}=$read;
        $lj_data_last{$volname}{$jobid}{read_bytes}=$read_bytes;

        $lj_data_out{$volname}{all}{read}+=$lj_data_out{$volname}{$jobid}{read};
        $lj_data_out{$volname}{all}{read_bytes}+=$lj_data_out{$volname}{$jobid}{read_bytes};

        $lj_data_out{all}{all}{read}+=$lj_data_out{$volname}{$jobid}{read};
        $lj_data_out{all}{all}{read_bytes}+=$lj_data_out{$volname}{$jobid}{read_bytes};

      }
      elsif ($data_type eq 'write' || $data_type eq 'write_bytes')
      {
        $$data=~/samples:\s*(\d+),.*sum:\s*(\d+)\s\}/;
        my $write=$1;
        my $write_bytes=$2;

        if (defined($lj_data_last{$volname}{$jobid}{$data_type}))
        {
          $lj_data_out{$volname}{$jobid}{write}=$write>=$lj_data_last{$volname}{$jobid}{write}?
                      $write-$lj_data_last{$volname}{$jobid}{write}:$write;
          $lj_data_out{$volname}{$jobid}{write_bytes}=$write_bytes>=$lj_data_last{$volname}{$jobid}{write_bytes}?
                      $write_bytes-$lj_data_last{$volname}{$jobid}{write_bytes}:$write_bytes;
        }
        else
        {
          $lj_data_out{$volname}{$jobid}{write}=$write;
          $lj_data_out{$volname}{$jobid}{write_bytes}=$write_bytes;
        }
        $lj_data_last{$volname}{$jobid}{write}=$write;
        $lj_data_last{$volname}{$jobid}{write_bytes}=$write_bytes;

        $lj_data_out{$volname}{all}{write}+=$lj_data_out{$volname}{$jobid}{write};
        $lj_data_out{$volname}{all}{write_bytes}+=$lj_data_out{$volname}{$jobid}{write_bytes};

        $lj_data_out{all}{all}{write}+=$lj_data_out{$volname}{$jobid}{write};
        $lj_data_out{all}{all}{write_bytes}+=$lj_data_out{$volname}{$jobid}{write_bytes};

      }
      elsif ($data_type ne 'job_stats' && $data_type ne 'snapshot_time')
      {
        $$data=~/samples:\s*(\d+),/;
        my $exec_cnt=$1;
        if (defined($lj_data_last{$volname}{$jobid}{$data_type}))
        {
          $lj_data_out{$volname}{$jobid}{$data_type}=$exec_cnt>=$lj_data_last{$volname}{$jobid}{$data_type}?
                      $exec_cnt-$lj_data_last{$volname}{$jobid}{$data_type}:$exec_cnt;
        }
        else
        {
          $lj_data_out{$volname}{$jobid}{$data_type}=$exec_cnt;
        }
        $lj_data_last{$volname}{$jobid}{$data_type}=$exec_cnt;

        $lj_data_out{$volname}{all}{$data_type}+=$lj_data_out{$volname}{$jobid}{$data_type};
        $lj_data_out{all}{all}{$data_type}+=$lj_data_out{$volname}{$jobid}{$data_type};
      }
    }
  }
}


sub fefssvIntervalEnd
{
  # clear not found data.
  foreach $volname (sort(keys(%lj_data_last)))
  {
    foreach $jobid (sort(keys(%{$lj_data_last{$volname}})))
    {
      if (!exists($find_flg{$volname}{$jobid}))
      {
        delete $lj_data_last{$volname}{$jobid};
      }
    }
  }
}


sub fefssvPrintBrief
{
  my $type=shift;
  my $line=shift;

  # create header and data line for brief.
  if ($type==1)
  {
    if ($vol_type eq 'mdt')
    {
      if ($fefs_ver==2.6)
      {
        $$line.="<----------------------------------------------------------------------Lustre Jobstats----------------------------------------------------------------------->";
      }
      else
      {
        $$line.="<------------------------------------------------------Lustre Jobstats------------------------------------------------------->";
      }
    }
    else
    {
      if ($fefs_ver==2.6)
      {
        $$line.="<------------------------------------------------------------Lustre Jobstats------------------------------------------------------------->";
      }
      else
      {
        $$line.="<-----------------------------Lustre Jobstats----------------------------->";
      }
    }
  }
  elsif ($type==2)
  {
    if ($vol_type eq 'mdt')
    {
      if ($fefs_ver==2.6)
      {
        $$line.="    open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync  samedir_rename crossdir_rename ";
      }
      else
      {
        $$line.="    open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync ";
      }
    }
    else
    {
      if ($fefs_ver==2.6)
      {
        $$line.="    read  read_bytes[B]    write write_bytes[B]  getattr  setattr    punch     sync  destroy   create   statfs get_info set_info quotactl ";
      }
      else
      {
        $$line.="    read  read_bytes[B]    write write_bytes[B]  setattr    punch     sync ";
      }
    }
  }
  elsif ($type==3)
  {
    if ($vol_type eq 'mdt')
    {
      if ($fefs_ver==2.6)
      {
        $$line.=sprintf("%8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %15s %15s ", "$lj_data_out{all}{all}{open}", "$lj_data_out{all}{all}{close}", "$lj_data_out{all}{all}{mknod}", "$lj_data_out{all}{all}{link}", "$lj_data_out{all}{all}{unlink}", "$lj_data_out{all}{all}{mkdir}", "$lj_data_out{all}{all}{rmdir}", "$lj_data_out{all}{all}{rename}", "$lj_data_out{all}{all}{getattr}", "$lj_data_out{all}{all}{setattr}", "$lj_data_out{all}{all}{getxattr}", "$lj_data_out{all}{all}{setxattr}", "$lj_data_out{all}{all}{statfs}", "$lj_data_out{all}{all}{sync}", "$lj_data_out{all}{all}{samedir_rename}", "$lj_data_out{all}{all}{crossdir_rename}");
      }
      else
      {
        $$line.=sprintf("%8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s ", "$lj_data_out{all}{all}{open}", "$lj_data_out{all}{all}{close}", "$lj_data_out{all}{all}{mknod}", "$lj_data_out{all}{all}{link}", "$lj_data_out{all}{all}{unlink}", "$lj_data_out{all}{all}{mkdir}", "$lj_data_out{all}{all}{rmdir}", "$lj_data_out{all}{all}{rename}", "$lj_data_out{all}{all}{getattr}", "$lj_data_out{all}{all}{setattr}", "$lj_data_out{all}{all}{getxattr}", "$lj_data_out{all}{all}{setxattr}", "$lj_data_out{all}{all}{statfs}", "$lj_data_out{all}{all}{sync}");
      }
    }
    else
    {
      if ($fefs_ver==2.6)
      {
        $$line.=sprintf("%8s %14s %8s %14s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s ", "$lj_data_out{all}{all}{read}", "$lj_data_out{all}{all}{read_bytes}", "$lj_data_out{all}{all}{write}", "$lj_data_out{all}{all}{write_bytes}", "$lj_data_out{all}{all}{getattr}", "$lj_data_out{all}{all}{setattr}", "$lj_data_out{all}{all}{punch}", "$lj_data_out{all}{all}{sync}", "$lj_data_out{all}{all}{destroy}", "$lj_data_out{all}{all}{create}", "$lj_data_out{all}{all}{statfs}", "$lj_data_out{all}{all}{get_info}", "$lj_data_out{all}{all}{set_info}", "$lj_data_out{all}{all}{quotactl}");
      }
      else
      {
        $$line.=sprintf("%8s %14s %8s %14s %8s %8s %8s ", "$lj_data_out{all}{all}{read}", "$lj_data_out{all}{all}{read_bytes}", "$lj_data_out{all}{all}{write}", "$lj_data_out{all}{all}{write_bytes}", "$lj_data_out{all}{all}{setattr}", "$lj_data_out{all}{all}{punch}", "$lj_data_out{all}{all}{sync}");
      }
    }
  }
}


sub fefssvPrintPlot
{
  my $type=shift;
  my $line=shift;

  my $datetime="";

  # create header and data line for plot.
  if ($type==1)
  {
    if ($vol_type eq 'mdt')
    {
      if ($fefs_ver==2.6)
      {
        $$line.="open${SEP}close${SEP}mknod${SEP}link${SEP}unlink${SEP}mkdir${SEP}rmdir${SEP}rename${SEP}getattr${SEP}setattr${SEP}getxattr${SEP}setxattr${SEP}statfs${SEP}sync${SEP}samedir_rename${SEP}crossdir_rename${SEP}";
      }
      else
      {
        $$line.="open${SEP}close${SEP}mknod${SEP}link${SEP}unlink${SEP}mkdir${SEP}rmdir${SEP}rename${SEP}getattr${SEP}setattr${SEP}getxattr${SEP}setxattr${SEP}statfs${SEP}sync${SEP}";
      }
    }
    else
    {
      if ($fefs_ver==2.6)
      {
        $$line.="read${SEP}read_bytes[B]${SEP}write${SEP}write_bytes[B]${SEP}getattr${SEP}setattr${SEP}punch${SEP}sync${SEP}destroy${SEP}create${SEP}statfs${SEP}get_info${SEP}set_info${SEP}quotactl${SEP}";
      }
      else
      {
        $$line.="read${SEP}read_bytes[B]${SEP}write${SEP}write_bytes[B]${SEP}setattr${SEP}punch${SEP}sync${SEP}";
      }
    }
  }
  elsif ($type==2)
  {
    if ($mode eq 'verbose')
    {
      if ($vol_type eq 'mdt')
      {
        if ($fefs_ver==2.6)
        {
          $$line.="MDT_NAME${SEP}JOBID${SEP}open${SEP}close${SEP}mknod${SEP}link${SEP}unlink${SEP}mkdir${SEP}rmdir${SEP}rename${SEP}getattr${SEP}setattr${SEP}getxattr${SEP}setxattr${SEP}statfs${SEP}sync${SEP}samedir_rename${SEP}crossdir_rename${SEP}";
        }
        else
        {
          $$line.="MDT_NAME${SEP}JOBID${SEP}open${SEP}close${SEP}mknod${SEP}link${SEP}unlink${SEP}mkdir${SEP}rmdir${SEP}rename${SEP}getattr${SEP}setattr${SEP}getxattr${SEP}setxattr${SEP}statfs${SEP}sync${SEP}";
        }
      }
      else
      {
        if ($fefs_ver==2.6)
        {
          $$line.="OST_NAME${SEP}JOBID${SEP}read${SEP}read_bytes[B]${SEP}write${SEP}write_bytes[B]${SEP}getattr${SEP}setattr${SEP}punch${SEP}sync${SEP}destroy${SEP}create${SEP}statfs${SEP}get_info${SEP}set_info${SEP}quotactl${SEP}";
        }
        else
        {
          $$line.="OST_NAME${SEP}JOBID${SEP}read${SEP}read_bytes[B]${SEP}write${SEP}write_bytes[B]${SEP}setattr${SEP}punch${SEP}sync${SEP}";
        }
      }
    }
    else
    {
      if ($vol_type eq 'mdt')
      {
        if ($fefs_ver==2.6)
        {
          $$line.="MDT_NAME${SEP}open${SEP}close${SEP}mknod${SEP}link${SEP}unlink${SEP}mkdir${SEP}rmdir${SEP}rename${SEP}getattr${SEP}setattr${SEP}getxattr${SEP}setxattr${SEP}statfs${SEP}sync${SEP}samedir_rename${SEP}crossdir_rename${SEP}";
        }
        else
        {
          $$line.="MDT_NAME${SEP}open${SEP}close${SEP}mknod${SEP}link${SEP}unlink${SEP}mkdir${SEP}rmdir${SEP}rename${SEP}getattr${SEP}setattr${SEP}getxattr${SEP}setxattr${SEP}statfs${SEP}sync${SEP}";
        }
      }
      else
      {
        if ($fefs_ver==2.6)
        {
        $$line.="OST_NAME${SEP}read${SEP}read_bytes[B]${SEP}write${SEP}write_bytes[B]${SEP}getattr${SEP}setattr${SEP}punch${SEP}sync${SEP}destroy${SEP}create${SEP}statfs${SEP}get_info${SEP}set_info${SEP}quotactl${SEP}";
        }
        else
        {
        $$line.="OST_NAME${SEP}read${SEP}read_bytes[B]${SEP}write${SEP}write_bytes[B]${SEP}setattr${SEP}punch${SEP}sync${SEP}";
        }
      }
    }
  }
  elsif ($type==3)
  {
    if ($vol_type eq 'mdt')
    {
      if ($fefs_ver==2.6)
      {
        $$line.="$SEP$lj_data_out{all}{all}{open}$SEP$lj_data_out{all}{all}{close}$SEP$lj_data_out{all}{all}{mknod}$SEP$lj_data_out{all}{all}{link}$SEP$lj_data_out{all}{all}{unlink}$SEP$lj_data_out{all}{all}{mkdir}$SEP$lj_data_out{all}{all}{rmdir}$SEP$lj_data_out{all}{all}{rename}$SEP$lj_data_out{all}{all}{getattr}$SEP$lj_data_out{all}{all}{setattr}$SEP$lj_data_out{all}{all}{getxattr}$SEP$lj_data_out{all}{all}{setxattr}$SEP$lj_data_out{all}{all}{statfs}$SEP$lj_data_out{all}{all}{sync}$SEP$lj_data_out{all}{all}{samedir_rename}$SEP$lj_data_out{all}{all}{crossdir_rename}";
      }
      else
      {
        $$line.="$SEP$lj_data_out{all}{all}{open}$SEP$lj_data_out{all}{all}{close}$SEP$lj_data_out{all}{all}{mknod}$SEP$lj_data_out{all}{all}{link}$SEP$lj_data_out{all}{all}{unlink}$SEP$lj_data_out{all}{all}{mkdir}$SEP$lj_data_out{all}{all}{rmdir}$SEP$lj_data_out{all}{all}{rename}$SEP$lj_data_out{all}{all}{getattr}$SEP$lj_data_out{all}{all}{setattr}$SEP$lj_data_out{all}{all}{getxattr}$SEP$lj_data_out{all}{all}{setxattr}$SEP$lj_data_out{all}{all}{statfs}$SEP$lj_data_out{all}{all}{sync}";
      }
    }
    else
    {
      if ($fefs_ver==2.6)
      {
        $$line.="$SEP$lj_data_out{all}{all}{read}$SEP$lj_data_out{all}{all}{read_bytes}$SEP$lj_data_out{all}{all}{write}$SEP$lj_data_out{all}{all}{write_bytes}$SEP$lj_data_out{all}{all}{getattr}$SEP$lj_data_out{all}{all}{setattr}$SEP$lj_data_out{all}{all}{punch}$SEP$lj_data_out{all}{all}{sync}$SEP$lj_data_out{all}{all}{destroy}$SEP$lj_data_out{all}{all}{create}$SEP$lj_data_out{all}{all}{statfs}$SEP$lj_data_out{all}{all}{get_info}$SEP$lj_data_out{all}{all}{set_info}$SEP$lj_data_out{all}{all}{quotactl}";
      }
      else
      {
        $$line.="$SEP$lj_data_out{all}{all}{read}$SEP$lj_data_out{all}{all}{read_bytes}$SEP$lj_data_out{all}{all}{write}$SEP$lj_data_out{all}{all}{write_bytes}$SEP$lj_data_out{all}{all}{setattr}$SEP$lj_data_out{all}{all}{punch}$SEP$lj_data_out{all}{all}{sync}";
      }
    }
  }
  elsif ($type==4)
  {
    delete $lj_data_out{all};

    if ($mode eq 'verbose')
    {
      foreach $volname (sort(keys(%lj_data_out)))
      {
        delete $lj_data_out{$volname}{all};
      }

      foreach $volname (sort(keys(%lj_data_out)))
      {
        foreach $jobid (sort(keys(%{$lj_data_out{$volname}})))
        {
          if ($vol_type eq 'mdt')
          {
            if ($fefs_ver==2.6)
            {
              $$line.="$datetime$SEP$volname$SEP$jobid$SEP$lj_data_out{$volname}{$jobid}{open}$SEP$lj_data_out{$volname}{$jobid}{close}$SEP$lj_data_out{$volname}{$jobid}{mknod}$SEP$lj_data_out{$volname}{$jobid}{link}$SEP$lj_data_out{$volname}{$jobid}{unlink}$SEP$lj_data_out{$volname}{$jobid}{mkdir}$SEP$lj_data_out{$volname}{$jobid}{rmdir}$SEP$lj_data_out{$volname}{$jobid}{rename}$SEP$lj_data_out{$volname}{$jobid}{getattr}$SEP$lj_data_out{$volname}{$jobid}{setattr}$SEP$lj_data_out{$volname}{$jobid}{getxattr}$SEP$lj_data_out{$volname}{$jobid}{setxattr}$SEP$lj_data_out{$volname}{$jobid}{statfs}$SEP$lj_data_out{$volname}{$jobid}{sync}$SEP$lj_data_out{$volname}{$jobid}{samedir_rename}$SEP$lj_data_out{$volname}{$jobid}{crossdir_rename}";
            }
            else
            {
              $$line.="$datetime$SEP$volname$SEP$jobid$SEP$lj_data_out{$volname}{$jobid}{open}$SEP$lj_data_out{$volname}{$jobid}{close}$SEP$lj_data_out{$volname}{$jobid}{mknod}$SEP$lj_data_out{$volname}{$jobid}{link}$SEP$lj_data_out{$volname}{$jobid}{unlink}$SEP$lj_data_out{$volname}{$jobid}{mkdir}$SEP$lj_data_out{$volname}{$jobid}{rmdir}$SEP$lj_data_out{$volname}{$jobid}{rename}$SEP$lj_data_out{$volname}{$jobid}{getattr}$SEP$lj_data_out{$volname}{$jobid}{setattr}$SEP$lj_data_out{$volname}{$jobid}{getxattr}$SEP$lj_data_out{$volname}{$jobid}{setxattr}$SEP$lj_data_out{$volname}{$jobid}{statfs}$SEP$lj_data_out{$volname}{$jobid}{sync}";
            }
          }
          else
          {
            if ($fefs_ver==2.6)
            {
              $$line.="$datetime$SEP$volname$SEP$jobid$SEP$lj_data_out{$volname}{$jobid}{read}$SEP$lj_data_out{$volname}{$jobid}{read_bytes}$SEP$lj_data_out{$volname}{$jobid}{write}$SEP$lj_data_out{$volname}{$jobid}{write_bytes}$SEP$lj_data_out{$volname}{$jobid}{getattr}$SEP$lj_data_out{$volname}{$jobid}{setattr}$SEP$lj_data_out{$volname}{$jobid}{punch}$SEP$lj_data_out{$volname}{$jobid}{sync}$SEP$lj_data_out{$volname}{$jobid}{destroy}$SEP$lj_data_out{$volname}{$jobid}{create}$SEP$lj_data_out{$volname}{$jobid}{statfs}$SEP$lj_data_out{$volname}{$jobid}{get_info}$SEP$lj_data_out{$volname}{$jobid}{set_info}$SEP$lj_data_out{$volname}{$jobid}{quotactl}";
            }
            else
            {
              $$line.="$datetime$SEP$volname$SEP$jobid$SEP$lj_data_out{$volname}{$jobid}{read}$SEP$lj_data_out{$volname}{$jobid}{read_bytes}$SEP$lj_data_out{$volname}{$jobid}{write}$SEP$lj_data_out{$volname}{$jobid}{write_bytes}$SEP$lj_data_out{$volname}{$jobid}{setattr}$SEP$lj_data_out{$volname}{$jobid}{punch}$SEP$lj_data_out{$volname}{$jobid}{sync}";
            }
          }

          if ($datetime eq '')
          {
            my ($seconds, $usecs);
            if (defined($lastSeconds[$rawPFlag]))
            {
              ($seconds, $usecs)=split(/\./, $lastSeconds[$rawPFlag]);
            }
            else
            {
              $seconds=$intSeconds;
              $usecs=sprintf("%06d", $intUsecs);
            }
            my $utcSecs=$seconds;

            $usecs='000'    if !defined($usecs);    # in case user specifies -om
            if ($hiResFlag)
            {
              $usecs=substr("${usecs}00", 0, 3);
              $seconds.=".$usecs";
            }
            my ($ss, $mm, $hh, $mday, $mon, $year)=localtime($seconds);
            my $date=($options=~/d/) ?
                     sprintf("%02d/%02d", $mon+1, $mday) :
                     sprintf("%d%02d%02d", $year+1900, $mon+1, $mday);
            my $time= sprintf("%02d:%02d:%02d", $hh, $mm, $ss);
            $datetime=(!$utcFlag) ? "\n$date$SEP$time": "\n$utcSecs";
            $datetime.=".$usecs"    if $options=~/m/;
          }
        }
      }
    }
    else
    {
      foreach $volname (sort(keys(%lj_data_out)))
      {
        if ($vol_type eq 'mdt')
        {
          if ($fefs_ver==2.6)
          {
            $$line.="$datetime$SEP$volname$SEP$lj_data_out{$volname}{all}{open}$SEP$lj_data_out{$volname}{all}{close}$SEP$lj_data_out{$volname}{all}{mknod}$SEP$lj_data_out{$volname}{all}{link}$SEP$lj_data_out{$volname}{all}{unlink}$SEP$lj_data_out{$volname}{all}{mkdir}$SEP$lj_data_out{$volname}{all}{rmdir}$SEP$lj_data_out{$volname}{all}{rename}$SEP$lj_data_out{$volname}{all}{getattr}$SEP$lj_data_out{$volname}{all}{setattr}$SEP$lj_data_out{$volname}{all}{getxattr}$SEP$lj_data_out{$volname}{all}{setxattr}$SEP$lj_data_out{$volname}{all}{statfs}$SEP$lj_data_out{$volname}{all}{sync}$SEP$lj_data_out{$volname}{all}{samedir_rename}$SEP$lj_data_out{$volname}{all}{crossdir_rename}";
          }
          else
          {
            $$line.="$datetime$SEP$volname$SEP$lj_data_out{$volname}{all}{open}$SEP$lj_data_out{$volname}{all}{close}$SEP$lj_data_out{$volname}{all}{mknod}$SEP$lj_data_out{$volname}{all}{link}$SEP$lj_data_out{$volname}{all}{unlink}$SEP$lj_data_out{$volname}{all}{mkdir}$SEP$lj_data_out{$volname}{all}{rmdir}$SEP$lj_data_out{$volname}{all}{rename}$SEP$lj_data_out{$volname}{all}{getattr}$SEP$lj_data_out{$volname}{all}{setattr}$SEP$lj_data_out{$volname}{all}{getxattr}$SEP$lj_data_out{$volname}{all}{setxattr}$SEP$lj_data_out{$volname}{all}{statfs}$SEP$lj_data_out{$volname}{all}{sync}";
          }
        }
        else
        {
          if ($fefs_ver==2.6)
          {
            $$line.="$datetime$SEP$volname$SEP$lj_data_out{$volname}{all}{read}$SEP$lj_data_out{$volname}{all}{read_bytes}$SEP$lj_data_out{$volname}{all}{write}$SEP$lj_data_out{$volname}{all}{write_bytes}$SEP$lj_data_out{$volname}{all}{getattr}$SEP$lj_data_out{$volname}{all}{setattr}$SEP$lj_data_out{$volname}{all}{punch}$SEP$lj_data_out{$volname}{all}{sync}$SEP$lj_data_out{$volname}{all}{destroy}$SEP$lj_data_out{$volname}{all}{create}$SEP$lj_data_out{$volname}{all}{statfs}$SEP$lj_data_out{$volname}{all}{get_info}$SEP$lj_data_out{$volname}{all}{set_info}$SEP$lj_data_out{$volname}{all}{quotactl}";
          }
          else
          {
            $$line.="$datetime$SEP$volname$SEP$lj_data_out{$volname}{all}{read}$SEP$lj_data_out{$volname}{all}{read_bytes}$SEP$lj_data_out{$volname}{all}{write}$SEP$lj_data_out{$volname}{all}{write_bytes}$SEP$lj_data_out{$volname}{all}{setattr}$SEP$lj_data_out{$volname}{all}{punch}$SEP$lj_data_out{$volname}{all}{sync}";
          }
        }

        # cleate datetime
        if ($datetime eq '')
        {
          my ($seconds, $usecs);
          if (defined($lastSeconds[$rawPFlag]))
          {
            ($seconds, $usecs)=split(/\./, $lastSeconds[$rawPFlag]);
          }
          else
          {
            $seconds=$intSeconds;
            $usecs=sprintf("%06d", $intUsecs);
          }
          my $utcSecs=$seconds;

          $usecs='000'    if !defined($usecs);    # in case user specifies -om
          if ($hiResFlag)
          {
            $usecs=substr("${usecs}00", 0, 3);
            $seconds.=".$usecs";
          }
          my ($ss, $mm, $hh, $mday, $mon, $year)=localtime($seconds);
          my $date=($options=~/d/) ?
                   sprintf("%02d/%02d", $mon+1, $mday) :
                   sprintf("%d%02d%02d", $year+1900, $mon+1, $mday);
          my $time=sprintf("%02d:%02d:%02d", $hh, $mm, $ss);
          $datetime=(!$utcFlag) ? "\n$date$SEP$time": "\n$utcSecs";
          $datetime.=".$usecs"    if $options=~/m/;
        }
      }
    }
  }
}


sub fefssvPrintVerbose
{
  my $printHeader=shift;
  my $homeFlag=shift;
  my $line=shift;

  if ($printHeader)
  {
    $$line.="\n"    if !$homeFlag;
    $$line.="# Lustre Jobstats\n";

    # create header for detail and verbose.
    if ($mode eq 'verbose')
    {
      if ($vol_type eq 'mdt')
      {
        if ($fefs_ver==2.6)
        {
          $$line.="#$miniFiller        MDT_NAME      JOBID     open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync  samedir_rename crossdir_rename\n";
        }
        else
        {
          $$line.="#$miniFiller        MDT_NAME      JOBID     open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync\n";
        }
      }
      else
      {
        if ($fefs_ver==2.6)
        {
          $$line.="#$miniFiller        OST_NAME      JOBID     read  read_bytes[B]    write write_bytes[B]  getattr  setattr    punch     sync  destroy   create   statfs get_info set_info quotactl\n";
        }
        else
        {
          $$line.="#$miniFiller        OST_NAME      JOBID     read  read_bytes[B]    write write_bytes[B]  setattr    punch     sync\n";
        }
      }
    }
    else
    {
      if ($vol_type eq 'mdt')
      {
        if ($fefs_ver==2.6)
        {
          $$line.="#$miniFiller        MDT_NAME     open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync  samedir_rename crossdir_rename\n";
        }
        else
        {
          $$line.="#$miniFiller        MDT_NAME     open    close    mknod     link   unlink    mkdir    rmdir   rename  getattr  setattr getxattr setxattr   statfs     sync\n";
        }
      }
      else
      {
        if ($fefs_ver==2.6)
        {
          $$line.="#$miniFiller        OST_NAME     read  read_bytes[B]    write write_bytes[B]  getattr  setattr    punch     sync  destroy   create   statfs get_info set_info quotactl\n";
        }
        else
        {
          $$line.="#$miniFiller        OST_NAME     read  read_bytes[B]    write write_bytes[B]  setattr    punch     sync\n";
        }
      }
    }
  }

  return    if $showColFlag;

  delete $lj_data_out{all};
  # create data line for detail and verbose.
  if ($mode eq 'verbose')
  {
    foreach $volname (sort(keys(%lj_data_out)))
    {
      delete $lj_data_out{$volname}{all};
    }

    foreach $volname (sort(keys(%lj_data_out)))
    {
      foreach $jobid (sort(keys(%{$lj_data_out{$volname}})))
      {
        if ($vol_type eq 'mdt')
        {
          if ($fefs_ver==2.6)
          {
            $$line.=sprintf("$datetime %16s %10s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %15s %15s\n", "$volname", "$jobid", "$lj_data_out{$volname}{$jobid}{open}", "$lj_data_out{$volname}{$jobid}{close}", "$lj_data_out{$volname}{$jobid}{mknod}", "$lj_data_out{$volname}{$jobid}{link}", "$lj_data_out{$volname}{$jobid}{unlink}", "$lj_data_out{$volname}{$jobid}{mkdir}", "$lj_data_out{$volname}{$jobid}{rmdir}", "$lj_data_out{$volname}{$jobid}{rename}", "$lj_data_out{$volname}{$jobid}{getattr}", "$lj_data_out{$volname}{$jobid}{setattr}", "$lj_data_out{$volname}{$jobid}{getxattr}", "$lj_data_out{$volname}{$jobid}{setxattr}", "$lj_data_out{$volname}{$jobid}{statfs}", "$lj_data_out{$volname}{$jobid}{sync}", "$lj_data_out{$volname}{$jobid}{samedir_rename}", "$lj_data_out{$volname}{$jobid}{crossdir_rename}");
         }
         else
         {
            $$line.=sprintf("$datetime %16s %10s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s\n", "$volname", "$jobid", "$lj_data_out{$volname}{$jobid}{open}", "$lj_data_out{$volname}{$jobid}{close}", "$lj_data_out{$volname}{$jobid}{mknod}", "$lj_data_out{$volname}{$jobid}{link}", "$lj_data_out{$volname}{$jobid}{unlink}", "$lj_data_out{$volname}{$jobid}{mkdir}", "$lj_data_out{$volname}{$jobid}{rmdir}", "$lj_data_out{$volname}{$jobid}{rename}", "$lj_data_out{$volname}{$jobid}{getattr}", "$lj_data_out{$volname}{$jobid}{setattr}", "$lj_data_out{$volname}{$jobid}{getxattr}", "$lj_data_out{$volname}{$jobid}{setxattr}", "$lj_data_out{$volname}{$jobid}{statfs}", "$lj_data_out{$volname}{$jobid}{sync}");
         }
        }
        else
        {
          if ($fefs_ver==2.6)
          {
            $$line.=sprintf("$datetime %16s %10s %8s %14s %8s %14s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s\n", "$volname", "$jobid", "$lj_data_out{$volname}{$jobid}{read}", "$lj_data_out{$volname}{$jobid}{read_bytes}", "$lj_data_out{$volname}{$jobid}{write}", "$lj_data_out{$volname}{$jobid}{write_bytes}", "$lj_data_out{$volname}{$jobid}{getattr}", "$lj_data_out{$volname}{$jobid}{setattr}", "$lj_data_out{$volname}{$jobid}{punch}", "$lj_data_out{$volname}{$jobid}{sync}", "$lj_data_out{$volname}{$jobid}{destroy}", "$lj_data_out{$volname}{$jobid}{create}", "$lj_data_out{$volname}{$jobid}{statfs}", "$lj_data_out{$volname}{$jobid}{get_info}", "$lj_data_out{$volname}{$jobid}{set_info}", "$lj_data_out{$volname}{$jobid}{quotactl}");
          }
          else
          {
            $$line.=sprintf("$datetime %16s %10s %8s %14s %8s %14s %8s %8s %8s\n", "$volname", "$jobid", "$lj_data_out{$volname}{$jobid}{read}", "$lj_data_out{$volname}{$jobid}{read_bytes}", "$lj_data_out{$volname}{$jobid}{write}", "$lj_data_out{$volname}{$jobid}{write_bytes}", "$lj_data_out{$volname}{$jobid}{setattr}", "$lj_data_out{$volname}{$jobid}{punch}", "$lj_data_out{$volname}{$jobid}{sync}");
          }
        }
      }
    }
  }
  else
  {
    foreach $volname (sort(keys(%lj_data_out)))
    {
      if ($vol_type eq 'mdt')
      {
        if ($fefs_ver==2.6)
        {
          $$line.=sprintf("$datetime %16s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %15s %15s\n", "$volname", "$lj_data_out{$volname}{all}{open}", "$lj_data_out{$volname}{all}{close}", "$lj_data_out{$volname}{all}{mknod}", "$lj_data_out{$volname}{all}{link}", "$lj_data_out{$volname}{all}{unlink}", "$lj_data_out{$volname}{all}{mkdir}", "$lj_data_out{$volname}{all}{rmdir}", "$lj_data_out{$volname}{all}{rename}", "$lj_data_out{$volname}{all}{getattr}", "$lj_data_out{$volname}{all}{setattr}", "$lj_data_out{$volname}{all}{getxattr}", "$lj_data_out{$volname}{all}{setxattr}", "$lj_data_out{$volname}{all}{statfs}", "$lj_data_out{$volname}{all}{sync}", "$lj_data_out{$volname}{all}{samedir_rename}", "$lj_data_out{$volname}{all}{crossdir_rename}");
        }
        else
        {
          $$line.=sprintf("$datetime %16s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s\n", "$volname", "$lj_data_out{$volname}{all}{open}", "$lj_data_out{$volname}{all}{close}", "$lj_data_out{$volname}{all}{mknod}", "$lj_data_out{$volname}{all}{link}", "$lj_data_out{$volname}{all}{unlink}", "$lj_data_out{$volname}{all}{mkdir}", "$lj_data_out{$volname}{all}{rmdir}", "$lj_data_out{$volname}{all}{rename}", "$lj_data_out{$volname}{all}{getattr}", "$lj_data_out{$volname}{all}{setattr}", "$lj_data_out{$volname}{all}{getxattr}", "$lj_data_out{$volname}{all}{setxattr}", "$lj_data_out{$volname}{all}{statfs}", "$lj_data_out{$volname}{all}{sync}");
        }
      }
      else
      {
        if ($fefs_ver==2.6)
        {
          $$line.=sprintf("$datetime %16s %8s %14s %8s %14s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s\n", "$volname", "$lj_data_out{$volname}{all}{read}", "$lj_data_out{$volname}{all}{read_bytes}", "$lj_data_out{$volname}{all}{write}", "$lj_data_out{$volname}{all}{write_bytes}", "$lj_data_out{$volname}{all}{getattr}", "$lj_data_out{$volname}{all}{setattr}", "$lj_data_out{$volname}{all}{punch}", "$lj_data_out{$volname}{all}{sync}", "$lj_data_out{$volname}{all}{destroy}", "$lj_data_out{$volname}{all}{create}", "$lj_data_out{$volname}{all}{statfs}", "$lj_data_out{$volname}{all}{get_info}", "$lj_data_out{$volname}{all}{set_info}", "$lj_data_out{$volname}{all}{quotactl}");
        }
        else
        {
          $$line.=sprintf("$datetime %16s %8s %14s %8s %14s %8s %8s %8s\n", "$volname", "$lj_data_out{$volname}{all}{read}", "$lj_data_out{$volname}{all}{read_bytes}", "$lj_data_out{$volname}{all}{write}", "$lj_data_out{$volname}{all}{write_bytes}", "$lj_data_out{$volname}{all}{setattr}", "$lj_data_out{$volname}{all}{punch}", "$lj_data_out{$volname}{all}{sync}");
        }
      }
    }
  }
}


sub fefssvUpdateHeader
{
  my $line=shift;

  $$line.="# FEFS:       ";

  if ($fefs_ver==1.8)
  {
    $$line.="Lustre 1.8 base\n"
  }
  else
  {
    $$line.="Lustre 2.6 base\n"
  }

}


sub fefssvGetHeader
{
  my $data=shift;
  if ($$data=~/FEFS:       Lustre 1\.8 base/)
  {
    $fefs_ver=1.8;
  }
  else
  {
    $fefs_ver=2.6;
  }
}


sub fefssvPrintExport
{
}
