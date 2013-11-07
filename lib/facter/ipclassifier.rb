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
# ipclassifier.rb: Classify IPs and add facts with details
# 18jun13 TJNII
require 'ipaddr'

interfaces = Facter.value('interfaces')

# createNetHash: Simple wrapper function to wrap IP integer conversions
# PRE: subnet & netmask == 0
# POST: None
# RETURN VALUE: Hash of inputs in integer form
def createNethash(subnet, netmask)
  return { "netmask" => IPAddr.new(netmask).to_i,
    "subnet" => IPAddr.new(subnet).to_i }
end

# Favoring readibility over execution time (via magic numbers) here.
internal_subnets = [ createNethash("10.0.0.0", "255.128.0.0") ]

# Subset of the reserved IPv4 blocks that we are likely to encounter
# https://en.wikipedia.org/wiki/Reserved_IP_addresses#Reserved_IPv4_addresses
nonpublic_subnets = [ createNethash("127.0.0.0", "255.0.0.0"),
                      createNethash("10.0.0.0", "255.0.0.0"),
                      createNethash("172.16.0.0", "255.240.0.0"),
                      createNethash("192.168.0.0", "255.255.0.0"),
                      createNethash("169.254.0.0", "255.255.0.0") ]


factips = Hash.new
factinterface = Hash.new
interfaces.split(",").sort.each do |i|
  ipaddress = Facter.value("ipaddress_" + i)
  if not ipaddress =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/
    next
  end
  ipint = IPAddr.new(ipaddress).to_i

  internal_subnets.each do |sd|
    if (ipint & sd["netmask"]) == sd["subnet"]
      if !factips.has_key?("internal")
        factips["internal"] = ipaddress
      end
      
      if !factinterface.has_key?("internal")
        factinterface["internal"] = [i]
      else
        factinterface["internal"].push(i)
      end

      next

    end
  end

  # Public IP.  Exclude known non-public blocks:
  reserved = false
  nonpublic_subnets.each do |sd|
    if (ipint & sd["netmask"]) == sd["subnet"]
      reserved = true
      break
    end
  end

  if reserved == false
    if !factips.has_key?("public")
      factips["public"] = ipaddress
    end

    if !factinterface.has_key?("public")
      factinterface["public"] = [i]
    else
      factinterface["public"].push(i)
    end
  end
end

factips.keys.sort.each do |k|
  Facter.add("ipaddress_" + k) do
    setcode do
      factips[k]
    end
  end
end

factinterface.keys.sort.each do |k|
  Facter.add("interfaces_" + k) do
    setcode do
      factinterface[k].join(',')
    end
  end
end
