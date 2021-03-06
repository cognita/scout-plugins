# =================================================================================
# mdstat
# 
# Created by Mark Hasse on 2008-04-15.
# =================================================================================
class MdStat < Scout::Plugin
  def build_report
    data = Hash.new
         
    mdstat = %x(cat /proc/mdstat).split(/\n/)
    
    spares = mdstat[1].scan(/\(S\)/).size
    failed = mdstat[1].scan(/\(F\)/).size

    mdstat[2] =~ /\[(\d*\/\d*)\].*\[(.+)\]/
    counts = $1
    if counts.nil?
      return error("Not applicable for RAID 0", "This plugin reports the number of active disks, spares, and failed disks. As RAID 0 isn't redundent, a single drive failure destroys the Array. These metrics aren't applicable for RAID 0.")
    end
    status = $2
    
    disk_counts = counts.split('/').map { |x| x.to_i } 
    disk_status = status.squeeze
    
    if disk_counts[0].class == Fixnum && disk_counts[1].class == Fixnum
      data[:active_disks] = disk_counts[0]
      data[:spares]       = spares
      data[:failed_disks] = failed
    else
      raise "Unexpected mdstat file format"
    end 
    
    if disk_counts[0] != disk_counts[1] || disk_status != 'U' || failed > 0 
      if memory(:mdstat_ok)
        remember(:mdstat_ok,false)
        alert(:subject => 'Disk failure detected')
      end
    else
      remember(:mdstat_ok,true)
    end

    report(data)
  end
end