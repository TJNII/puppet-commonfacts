# Copyright 2013 Tom Noonan II (TJNII)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
#
# mounts.rb: Generate filesystem mount facts from the fstab
# (Intentionally NOT the mtab.)
# 15jun13 TJNII
#

file = File.new("/etc/fstab", "r")
mountpoints = Hash.new
dupetracker = Hash.new
mountslist  = Array.new
while (line = file.gets)
  if not line =~ /^\s*#/ and not line =~ /^\s*$/
    data = line.split(/\s+/)
    
    # Don't monitor noauto filesystems
    if not data[3] =~ /noauto/i
      # Filesystem type
      case data[2]
      when "proc", "swap", "devpts", "sysfs", "binfmt_misc", "xenfs"
        next
        
      else
        mountslist.push(data[1])

        # Facter facts need to be lowercase
        # downcase the key, and save a duplicate tracker
        key = data[1].downcase
        if dupetracker.has_key?(key)
          dupetracker[key] = true
        else
          mountpoints[key] = data[2]
          dupetracker[key] = false
        end
      end
    end
  end
end
file.close

# This is an independent loop because I was getting weird
# off-by-one errors in the main loop above.
mountpoints.keys.sort.each do |k|
  # Only save non-duplicates
  # Currently relying on the clients to catch when this is omitted.
  if dupetracker[k] == false
    Facter.add("mounttype_" + k) do
      setcode do
        mountpoints[k]
      end
    end
  end
end

Facter.add("mountpoints") do
  setcode do
    # mountpoints is not downcased, so mountpoints.keys no longer works
    mountslist.sort.join(',')
  end
end
