# Fact: centrify_hostname
#
# Purpose: Return fact on centrify_hostname
#
#
Facter.add("centrify_hostname") do
  setcode do
    centrify_hostname = Facter.value("hostname").split(//).last(14).to_s
  end
end
