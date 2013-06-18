#
# mounts.rb: Generate filesystem mount facts from the fstab
# (Intentionally NOT the mtab.)
# 15jun13 TJNII
#

file = File.new("/etc/fstab", "r")
mountpoints = Hash.new
while (line = file.gets)
  if not line =~ /^\s*#/ and not line =~ /^\s*$/
    data = line.split(/\s+/)

    # Don't monitor noauto filesystems
    if not data[3] =~ /noauto/i
      # Filesystem type
      case data[2]
        when "proc", "swap"
           next

        else
           mountpoints[data[1]] = data[2]
      end
      
    end
  end
end
file.close

# This is an independent loop because I was getting weird
# off-by-one errors in the main loop above.
mountpoints.keys.sort.each do |k|
  Facter.add("mounttype_" + k) do
    setcode do
      mountpoints[k]
    end
  end
end

Facter.add("mountpoints") do
  setcode do
    mountpoints.keys.sort.join(',')
  end
end
