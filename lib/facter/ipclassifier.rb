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
interfaces.split(",").each do |i|
  ipaddress = Facter.value("ipaddress_" + i)
  ipint = IPAddr.new(ipaddress).to_i
  
  internal_subnets.each do |sd|
    if (ipint & sd["netmask"]) == sd["subnet"]
      factips["internal"] = ipaddress
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
    factips["public"] = ipaddress
  end
end  
  
factips.keys.sort.each do |k|
  Facter.add("ipaddress_" + k) do
    setcode do
      factips[k]
    end
  end
end
