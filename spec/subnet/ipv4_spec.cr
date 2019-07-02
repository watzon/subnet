require "../subnet_spec"

VALID_IPV4 = {
  "0.0.0.0/0"              => ["0.0.0.0", "0"],
  "10.0.0.0"               => ["10.0.0.0", "32"],
  "10.0.0.1"               => ["10.0.0.1", "32"],
  "10.0.0.1/24"            => ["10.0.0.1", "24"],
  "10.0.0.1/255.255.255.0" => ["10.0.0.1", "24"],
}

INVALID_IPV4 = ["10.0.0.256",
                "10.0.0.0.0",
                "10.0.0",
                "10.0"]

VALID_IPV4_RANGE = ["10.0.0.1-254",
                    "10.0.1-254.0",
                    "10.1-254.0.0"]

NETMASK_VALUES = {
  "0.0.0.0/0"        => "0.0.0.0",
  "10.0.0.0/8"       => "255.0.0.0",
  "172.16.0.0/16"    => "255.255.0.0",
  "192.168.0.0/24"   => "255.255.255.0",
  "192.168.100.4/30" => "255.255.255.252",
  "192.168.12.4/32"  => "255.255.255.255",
}

DECIMAL_VALUES = {
  "0.0.0.0/0"        => 0,
  "10.0.0.0/8"       => 167772160,
  "172.16.0.0/16"    => 2886729728,
  "192.168.0.0/24"   => 3232235520,
  "192.168.100.4/30" => 3232261124,
}

HEX_VALUES = {
  "10.0.0.0"      => "0a000000",
  "172.16.5.4"    => "ac100504",
  "192.168.100.4" => "c0a86404",
}

IP      = Subnet::IPv4.new("172.16.10.1/24")
NETWORK = Subnet::IPv4.new("172.16.10.0/24")

BROADCAST = {
  "10.0.0.0/8"       => "10.255.255.255/8",
  "172.16.0.0/16"    => "172.16.255.255/16",
  "192.168.0.0/24"   => "192.168.0.255/24",
  "192.168.100.4/30" => "192.168.100.7/30",
  "192.168.12.3/31"  => "255.255.255.255/31",
  "10.0.0.1/32"      => "10.0.0.1/32",
}

NETWORKS = {
  "10.5.4.3/8"       => "10.0.0.0/8",
  "172.16.5.4/16"    => "172.16.0.0/16",
  "192.168.4.3/24"   => "192.168.4.0/24",
  "192.168.100.5/30" => "192.168.100.4/30",
  "192.168.1.3/31"   => "192.168.1.2/31",
  "192.168.2.5/32"   => "192.168.2.5/32",
}

CLASS_A = Subnet::IPv4.new("10.0.0.1/8")
CLASS_B = Subnet::IPv4.new("172.16.0.1/16")
CLASS_C = Subnet::IPv4.new("192.168.0.1/24")

CLASSFUL = {
  "10.1.1.1"  => 8,
  "150.1.1.1" => 16,
  "200.1.1.1" => 24,
}

IN_RANGE = {
  "10.32.0.1" => {"10.32.0.253", 253},
  "192.0.0.0" => {"192.1.255.255", 131072},
}

LINK_LOCAL = [
  "169.254.0.0",
  "169.254.255.255",
  "169.254.12.34",
  "169.254.0.0/16",
  "169.254.0.0/17",
]

NOT_LINK_LOCAL = [
  "127.0.0.1",
  "127.0.1.1",
  "192.168.0.100",
  "169.255.0.0",
  "169.254.0.0/15",
  "0.0.0.0",
  "255.255.255.255",
]

describe Subnet::IPv4 do
  describe "#initialize" do
    it "should create a new IPv4 instance" do
      VALID_IPV4.keys.each do |i|
        ip = Subnet::IPv4.new(i)
        ip.should be_a Subnet::IPv4
      end

      IP.prefix.should be_a Subnet::Prefix32
    end

    it "should throw an error with incorrect format" do
      INVALID_IPV4.each do |i|
        expect_raises(ArgumentError) do
          Subnet::IPv4.new(i)
        end
      end

      expect_raises(ArgumentError) do
        Subnet::IPv4.new("10.0.0.0/asd")
      end
    end

    it "should initialize without a prefix" do
      ip = Subnet::IPv4.new("10.10.0.0")
      ip.prefix.should be_a Subnet::Prefix32
      ip.prefix.to_i.should eq 32
    end

    it "should have correct attributes" do
      VALID_IPV4.each do |(arg, attr)|
        ip = Subnet::IPv4.new(arg)
        ip.address.should eq attr.first
        ip.prefix.to_s.should eq attr.last
      end
    end
  end

  describe "#octets" do
    it "should have an octet" do
      ip = Subnet::IPv4.new("10.1.2.3/8")
      ip.octets.should eq [10, 1, 2, 3]
    end
  end

  describe "#data" do
    it "should output binary data" do
      IP.data.should eq "\xAC\u0010\n\u0001"
    end
  end

  describe "#to_string" do
    it "should convert to a string in cannonical form" do
      VALID_IPV4.each do |(arg, attr)|
        ip = Subnet::IPv4.new(arg)
        ip.to_string.should eq attr.join('/')
      end
    end
  end

  describe "#to_s" do
    it "should convert to a string in normal form" do
      VALID_IPV4.each do |(arg, attr)|
        ip = Subnet::IPv4.new(arg)
        ip.to_s.should eq attr.first
      end
    end
  end

  describe "#netmask" do
    it "should have a valid netmask" do
      NETMASK_VALUES.each do |(addr, mask)|
        ip = Subnet::IPv4.new(addr)
        ip.netmask.should eq mask
      end
    end

    it "should have correct prefix for netmask" do
      ip = Subnet::IPv4.new("10.1.1.1/16")
      ip.prefix.to_i.should eq 16
      ip.netmask = "255.255.255.0"
      ip.prefix.to_i.should eq 24
    end
  end

  describe "#to_u32" do
    it "should convert to u32" do
      DECIMAL_VALUES.each do |(addr, int)|
        ip = Subnet::IPv4.new(addr)
        ip.to_u32.should eq int
      end
    end
  end

  describe "#hexstring" do
    it "should convert to a hex value" do
      HEX_VALUES.each do |(addr, hex)|
        ip = Subnet::IPv4.new(addr)
        ip.hexstring.should eq hex
      end
    end
  end

  describe "#broadcast" do
    it "should return the broadcast address" do
      BROADCAST.each do |(addr, bcast)|
        ip = Subnet::IPv4.new(addr)
        ip.broadcast.should be_a Subnet::IPv4
        ip.broadcast.to_string.should eq bcast
      end
    end
  end

  describe "#network" do
    it "should return the network address" do
      NETWORKS.each do |(addr, net)|
        ip = Subnet::IPv4.new(addr)
        ip.network.should be_a Subnet::IPv4
        ip.network.to_string.should eq net
      end
    end
  end

  describe "#network?" do
    it "should detect network addresses" do
      NETWORK.network?.should be_true
      IP.network?.should be_false
    end

    it "should detect one address network" do
      network = Subnet::IPv4.new("172.16.10.1/32")
      network.network?.should be_false
    end
  end

  describe "#bits" do
    it "should return a bit string representing the address" do
      ip = Subnet::IPv4.new("127.0.0.1")
      ip.bits.should eq "01111111000000000000000000000001"
    end
  end

  describe "#first" do
    it "should return a new IPv4 object with the first host in range" do
      ip = Subnet::IPv4.new("192.168.100.0/24")
      ip.first.should be_a Subnet::IPv4
      ip.first.to_s.should eq "192.168.100.1"

      ip = Subnet::IPv4.new("192.168.100.50/24")
      ip.first.should be_a Subnet::IPv4
      ip.first.to_s.should eq "192.168.100.1"

      ip = Subnet::IPv4.new("192.168.100.50/32")
      ip.first.should be_a Subnet::IPv4
      ip.first.to_s.should eq "192.168.100.50"

      ip = Subnet::IPv4.new("192.168.100.50/31")
      ip.first.should be_a Subnet::IPv4
      ip.first.to_s.should eq "192.168.100.50"
    end
  end

  describe "#last" do
    it "should return a new IPv4 object with the last host in range" do
      ip = Subnet::IPv4.new("192.168.100.0/24")
      ip.last.should be_a Subnet::IPv4
      ip.last.to_s.should eq "192.168.100.254"

      ip = Subnet::IPv4.new("192.168.100.50/24")
      ip.last.should be_a Subnet::IPv4
      ip.last.to_s.should eq "192.168.100.254"

      ip = Subnet::IPv4.new("192.168.100.50/32")
      ip.last.should be_a Subnet::IPv4
      ip.last.to_s.should eq "192.168.100.50"

      ip = Subnet::IPv4.new("192.168.100.50/31")
      ip.last.should be_a Subnet::IPv4
      ip.last.to_s.should eq "192.168.100.51"
    end
  end

  describe "#each_host" do
    it "should iterate over all the hosts for a given network" do
      ip = Subnet::IPv4.new("10.0.0.1/29")
      arr = [] of String
      ip.each_host { |i| arr << i.to_s }
      expected = ["10.0.0.1", "10.0.0.2", "10.0.0.3",
                  "10.0.0.4", "10.0.0.5", "10.0.0.6"]
      arr.should eq expected
    end
  end

  describe "#each" do
    it "should iterate over all the ip addresses for a given network" do
      ip = Subnet::IPv4.new("10.0.0.1/29")
      arr = [] of String
      ip.each { |i| arr << i.to_s }
      expected = ["10.0.0.0", "10.0.0.1", "10.0.0.2",
                  "10.0.0.3", "10.0.0.4", "10.0.0.5",
                  "10.0.0.6", "10.0.0.7"]
      arr.should eq expected
    end
  end

  describe "#size" do
    it "should return the number of ip addresses in a network" do
      ip = Subnet::IPv4.new("10.0.0.1/29")
      ip.size.should eq 8
    end
  end

  describe "#hosts" do
    it "should return all the hosts in a given network" do
      ip = Subnet::IPv4.new("10.0.0.1/29")
      expected = ["10.0.0.1", "10.0.0.2", "10.0.0.3",
                  "10.0.0.4", "10.0.0.5", "10.0.0.6"]
      hosts = ip.hosts.map(&.to_s)
      hosts.should eq expected
    end
  end

  describe "#network_u32" do
    it "should return the network address as a u32" do
      IP.network_u32.should eq 2886732288
    end
  end

  describe "#broadcast_u32" do
    it "should return the broadcast address as a u32" do
      IP.broadcast_u32.should eq 2886732543
    end
  end

  describe "#includes?" do
    it "should check whether a subnet includes an ip address" do
      ip = Subnet.parse("192.168.10.100/24")
      addr = Subnet.parse("192.168.10.102/24")
      ip.includes?(addr).should be_true
      ip.includes?(Subnet::IPv4.new("172.16.0.48")).should be_false

      ip = Subnet::IPv4.new("10.0.0.0/8")
      ip.includes?(Subnet::IPv4.new("10.0.0.0/9")).should be_true
      ip.includes?(Subnet::IPv4.new("10.1.1.1/32")).should be_true
      ip.includes?(Subnet::IPv4.new("10.1.1.1/9")).should be_true
      ip.includes?(Subnet::IPv4.new("172.16.0.0/16")).should be_false
      ip.includes?(Subnet::IPv4.new("10.0.0.0/7")).should be_false
      ip.includes?(Subnet::IPv4.new("5.5.5.5/32")).should be_false
      ip.includes?(Subnet::IPv4.new("11.0.0.0/8")).should be_false

      ip = Subnet::IPv4.new("13.13.0.0/13")
      ip.includes?(Subnet::IPv4.new("13.16.0.0/32")).should be_false
    end
  end

  describe "#includes_all?" do
    it "should check whether a subnet includes all the given ip addresses" do
      ip = Subnet::IPv4.new("192.168.10.100/24")
      addr1 = Subnet::IPv4.new("192.168.10.102/24")
      addr2 = Subnet::IPv4.new("192.168.10.103/24")
      ip.includes_all?(addr1, addr2).should be_true
      ip.includes_all?(addr1, Subnet::IPv4.new("13.16.0.0/32"))
    end
  end

  describe "#ipv4?" do
    it "should be true" do
      IP.ipv4?.should be_true
    end
  end

  describe "#ipv6?" do
    it "should be false" do
      IP.ipv6?.should be_false
    end
  end

  describe "private?" do
    it "should check if an ip belongs to a private network" do
      Subnet::IPv4.new("192.168.10.50/24").private?.should be_true
      Subnet::IPv4.new("192.168.10.50/16").private?.should be_true
      Subnet::IPv4.new("172.16.77.40/24").private?.should be_true
      Subnet::IPv4.new("172.16.10.50/14").private?.should be_true
      Subnet::IPv4.new("10.10.10.10/10").private?.should be_true
      Subnet::IPv4.new("10.0.0.0/8").private?.should be_true
      Subnet::IPv4.new("192.168.10.50/12").private?.should be_false
      Subnet::IPv4.new("3.3.3.3").private?.should be_false
      Subnet::IPv4.new("10.0.0.0/7").private?.should be_false
      Subnet::IPv4.new("172.32.0.0/12").private?.should be_false
      Subnet::IPv4.new("172.16.0.0/11").private?.should be_false
      Subnet::IPv4.new("192.0.0.2/24").private?.should be_false
    end
  end

  describe "#link_local?" do
    it "should check if an ip address belongs to a link local network" do
      LINK_LOCAL.each do |addr|
        Subnet::IPv4.new(addr).link_local?.should be_true
      end

      NOT_LINK_LOCAL.each do |addr|
        Subnet::IPv4.new(addr).link_local?.should be_false
      end
    end
  end

  describe "#[]" do
    it "should select the octet value at index" do
      IP[0].should eq 172
      IP[1].should eq 16
      IP[2].should eq 10
      IP[3].should eq 1
    end
  end

  describe "#a?" do
    it "should accurately determine if a network is class a" do
      CLASS_A.a?.should be_true
      CLASS_B.a?.should be_false
      CLASS_C.a?.should be_false
    end
  end

  describe "#b?" do
    it "should accurately determine if a network is class b" do
      CLASS_A.b?.should be_false
      CLASS_B.b?.should be_true
      CLASS_C.b?.should be_false
    end
  end

  describe "#c?" do
    it "should accurately determine if a network is class c" do
      CLASS_A.c?.should be_false
      CLASS_B.c?.should be_false
      CLASS_C.c?.should be_true
    end
  end

  describe "#to_ipv6" do
    it "should convert ipv4 address to ipv6" do
      IP.to_ipv6.should eq "ac10:0a01"
    end
  end

  describe "#reverse" do
    it "should return the address in in-addr.arpa format" do
      IP.reverse.should eq "1.10.16.172.in-addr.arpa"
    end
  end

  describe "Comparison operators" do
    it "should compare two addresses" do
      ip1 = Subnet::IPv4.new("10.1.1.1/8")
      ip2 = Subnet::IPv4.new("10.1.1.1/16")
      ip3 = Subnet::IPv4.new("172.16.1.1/14")
      ip4 = Subnet::IPv4.new("10.1.1.1/8")

      (ip1 < ip2).should be_true
      (ip1 > ip2).should be_false
      (ip2 < ip1).should be_false

      (ip2 < ip3).should be_true
      (ip2 > ip3).should be_false

      (ip1 < ip3).should be_true
      (ip1 > ip3).should be_false
      (ip3 < ip1).should be_false

      (ip1 == ip1).should be_true
      (ip1 == ip4).should be_true
    end

    it "should be in the correct order" do
      ip1 = Subnet::IPv4.new("10.1.1.1/8")
      ip2 = Subnet::IPv4.new("10.1.1.1/16")
      ip3 = Subnet::IPv4.new("172.16.1.1/14")

      arr = ["10.1.1.1/8", "10.1.1.1/16", "172.16.1.1/14"]
      [ip1, ip2, ip3].sort.map(&.to_string).should eq arr
    end

    it "should work with same prefix" do
      ip1 = Subnet::IPv4.new("10.0.0.0/24")
      ip2 = Subnet::IPv4.new("10.0.0.0/16")
      ip3 = Subnet::IPv4.new("10.0.0.0/8")

      arr = ["10.0.0.0/8", "10.0.0.0/16", "10.0.0.0/24"]
      [ip1, ip2, ip3].sort.map(&.to_string).should eq arr
    end

    it "should compare with spaceship operator" do
      ip1 = Subnet::IPv4.new("127.0.0.1")
      ip2 = Subnet::IPv6.new("::1")

      (ip1 <=> ip2).should eq 1
    end
  end

  describe "#-" do
    it "should subtract two addresses" do
      ip1 = Subnet::IPv4.new("10.1.1.1/8")
      ip2 = Subnet::IPv4.new("10.1.1.10/8")

      (ip2 - ip1).should eq 9
      (ip1 - ip2).should eq 9
    end
  end

  describe "#+" do
    it "should add two addresses" do
      ip1 = Subnet::IPv4.new("172.16.10.1/24")
      ip2 = Subnet::IPv4.new("172.16.11.2/24")
      (ip1 + ip2).map(&.to_string).should eq ["172.16.10.0/23"]

      ip2 = Subnet::IPv4.new("172.16.12.2/24")
      (ip1 + ip2).map(&.to_string).should eq [ip1.network.to_string, ip2.network.to_string]

      ip1 = Subnet::IPv4.new("10.0.0.0/23")
      ip2 = Subnet::IPv4.new("10.0.2.0/24")
      (ip1 + ip2).map(&.to_string).should eq ["10.0.0.0/23", "10.0.2.0/24"]

      ip1 = Subnet::IPv4.new("10.0.0.0/23")
      ip2 = Subnet::IPv4.new("10.0.2.0/24")
      (ip2 + ip1).map(&.to_string).should eq ["10.0.0.0/23", "10.0.2.0/24"]

      ip1 = Subnet::IPv4.new("10.0.0.0/16")
      ip2 = Subnet::IPv4.new("10.0.2.0/24")
      (ip1 + ip2).map(&.to_string).should eq ["10.0.0.0/16"]

      ip1 = Subnet::IPv4.new("10.0.0.0/23")
      ip2 = Subnet::IPv4.new("10.1.0.0/24")
      (ip1 + ip2).map(&.to_string).should eq ["10.0.0.0/23", "10.1.0.0/24"]
    end
  end

  describe "#split" do
    it "should split a network into different subnets" do
      expect_raises(ArgumentError) { IP.split(0) }
      expect_raises(ArgumentError) { IP.split(257) }

      IP.split(1).first.should eq IP.network

      arr = ["172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
             "172.16.10.96/27", "172.16.10.128/27", "172.16.10.160/27",
             "172.16.10.192/27", "172.16.10.224/27"]
      NETWORK.split(8).map(&.to_string).should eq arr

      arr = ["172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
             "172.16.10.96/27", "172.16.10.128/27", "172.16.10.160/27",
             "172.16.10.192/26"]
      NETWORK.split(7).map(&.to_string).should eq arr

      arr = ["172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
             "172.16.10.96/27", "172.16.10.128/26", "172.16.10.192/26"]
      NETWORK.split(6).map(&.to_string).should eq arr

      arr = ["172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
             "172.16.10.96/27", "172.16.10.128/25"]
      NETWORK.split(5).map(&.to_string).should eq arr

      arr = ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26",
             "172.16.10.192/26"]
      NETWORK.split(4).map(&.to_string).should eq arr

      arr = ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/25"]
      NETWORK.split(3).map(&.to_string).should eq arr

      arr = ["172.16.10.0/25", "172.16.10.128/25"]
      NETWORK.split(2).map(&.to_string).should eq arr

      arr = ["172.16.10.0/24"]
      NETWORK.split(1).map(&.to_string).should eq arr
    end
  end

  describe "#subnet" do
    it "should calculate subnets associated with a prefix" do
      expect_raises(ArgumentError) { NETWORK.subnet(23) }
      expect_raises(ArgumentError) { NETWORK.subnet(33) }

      arr = ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26",
             "172.16.10.192/26"]
      NETWORK.subnet(26).map(&.to_string).should eq arr
      arr = ["172.16.10.0/25", "172.16.10.128/25"]
      NETWORK.subnet(25).map(&.to_string).should eq arr

      arr = ["172.16.10.0/24"]
      NETWORK.subnet(24).map(&.to_string).should eq arr
    end
  end

  describe "#supernet" do
    it "should calculate supernets associated with a prefix" do
      expect_raises(ArgumentError) { IP.supernet(24) }

      IP.supernet(0).to_string.should eq "0.0.0.0/0"
      IP.supernet(-2).to_string.should eq "0.0.0.0/0"
      IP.supernet(23).to_string.should eq "172.16.10.0/23"
      IP.supernet(22).to_string.should eq "172.16.8.0/22"
    end
  end

  describe ".parse_u32" do
    it "should create a new IPv4 object from a u32" do
      DECIMAL_VALUES.each do |(addr, int)|
        ip = Subnet::IPv4.parse_u32(int)
        ip.prefix = addr.split('/').last.to_u32
        ip.to_string.should eq addr
      end
    end
  end

  describe ".extract" do
    it "should extract an ipv4 address from a string" do
      str = "foobar172.16.10.1barbaz"
      Subnet::IPv4.extract(str).to_s.should eq "172.16.10.1"
    end
  end

  describe ".summarize" do
    it "should summarize a list of ips" do
      # Should return self if only one network given
      Subnet::IPv4.summarize(IP).should eq [IP.network]

      # Summarize homogeneous networks
      ip1 = Subnet::IPv4.new("172.16.10.1/24")
      ip2 = Subnet::IPv4.new("172.16.11.2/24")
      Subnet::IPv4.summarize(ip1, ip2).map(&.to_string).should eq ["172.16.10.0/23"]

      ip1 = Subnet::IPv4.new("10.0.0.1/24")
      ip2 = Subnet::IPv4.new("10.0.1.1/24")
      ip3 = Subnet::IPv4.new("10.0.2.1/24")
      ip4 = Subnet::IPv4.new("10.0.3.1/24")
      Subnet::IPv4.summarize(ip1, ip2, ip3, ip4).map(&.to_string).should eq ["10.0.0.0/22"]
      Subnet::IPv4.summarize(ip4, ip3, ip2, ip1).map(&.to_string).should eq ["10.0.0.0/22"]

      # Summarize non homogeneous networks
      ip1 = Subnet::IPv4.new("10.0.0.0/23")
      ip2 = Subnet::IPv4.new("10.0.2.0/24")
      Subnet::IPv4.summarize(ip1, ip2).map(&.to_string).should eq ["10.0.0.0/23", "10.0.2.0/24"]

      ip1 = Subnet::IPv4.new("10.0.0.0/16")
      ip2 = Subnet::IPv4.new("10.0.2.0/24")
      Subnet::IPv4.summarize(ip1, ip2).map(&.to_string).should eq ["10.0.0.0/16"]

      ip1 = Subnet::IPv4.new("10.0.0.0/23")
      ip2 = Subnet::IPv4.new("10.1.0.0/24")
      Subnet::IPv4.summarize(ip1, ip2).map(&.to_string).should eq ["10.0.0.0/23", "10.1.0.0/24"]

      ip1 = Subnet::IPv4.new("10.0.0.0/23")
      ip2 = Subnet::IPv4.new("10.0.2.0/23")
      ip3 = Subnet::IPv4.new("10.0.4.0/24")
      ip4 = Subnet::IPv4.new("10.0.6.0/24")
      Subnet::IPv4.summarize(ip1, ip2, ip3, ip4).map(&.to_string).should eq ["10.0.0.0/22", "10.0.4.0/24", "10.0.6.0/24"]

      ip1 = Subnet::IPv4.new("10.0.1.1/24")
      ip2 = Subnet::IPv4.new("10.0.2.1/24")
      ip3 = Subnet::IPv4.new("10.0.3.1/24")
      ip4 = Subnet::IPv4.new("10.0.4.1/24")
      result = ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"]
      Subnet::IPv4.summarize(ip1, ip2, ip3, ip4).map(&.to_string).should eq result
      Subnet::IPv4.summarize(ip4, ip3, ip2, ip1).map(&.to_string).should eq result

      ip1 = Subnet::IPv4.new("10.0.1.1/24")
      ip2 = Subnet::IPv4.new("10.10.2.1/24")
      ip3 = Subnet::IPv4.new("172.16.0.1/24")
      ip4 = Subnet::IPv4.new("172.16.1.1/24")
      result = ["10.0.1.0/24", "10.10.2.0/24", "172.16.0.0/23"]
      Subnet::IPv4.summarize(ip1, ip2, ip3, ip4).map(&.to_string).should eq result

      ips = [Subnet::IPv4.new("10.0.0.12/30"),
             Subnet::IPv4.new("10.0.100.0/24")]
      result = ["10.0.0.12/30", "10.0.100.0/24"]
      Subnet::IPv4.summarize(ips).map(&.to_string).should eq result

      ips = [Subnet::IPv4.new("172.16.0.0/31"),
             Subnet::IPv4.new("10.10.2.1/32")]
      result = ["10.10.2.1/32", "172.16.0.0/31"]
      Subnet::IPv4.summarize(ips).map(&.to_string).should eq result

      ips = [Subnet::IPv4.new("172.16.0.0/32"),
             Subnet::IPv4.new("10.10.2.1/32")]
      result = ["10.10.2.1/32", "172.16.0.0/32"]
      Subnet::IPv4.summarize(ips).map(&.to_string).should eq result
    end
  end

  describe ".parse_data" do
    it "should create a new IPv4 from an Array of Bytes" do
      ip = Subnet::IPv4.parse_data Bytes[172, 16, 10, 1]
      ip.prefix = 24
      ip.to_string.should eq "172.16.10.1/24"
    end
  end

  describe ".parse_classful" do
    it "should parse an address in a classful way" do
      CLASSFUL.each do |ip, prefix|
        res = Subnet::IPv4.parse_classful(ip)
        res.prefix.should eq prefix
        res.to_string.should eq "#{ip}/#{prefix}"
      end

      expect_raises(ArgumentError) { Subnet::IPv4.parse_classful("192.168.256.257") }
    end
  end

  describe "#to" do
    it "should get a list of ips between self and the specified ip" do
      IN_RANGE.each do |(s, d)|
        ip = Subnet::IPv4.new(s)
        ip.to(d[0]).size.should eq d[1]
      end
    end
  end

  describe "#[]=" do
    ip = Subnet::IPv4.new("10.0.1.15/32")
    ip[1] = 15
    ip.to_string.should eq "10.15.1.15/32"

    ip = Subnet::IPv4.new("172.16.100.1")
    ip[3] = 200
    ip.to_string.should eq "172.16.100.200/32"

    ip = Subnet::IPv4.new("192.168.199.0/24")
    ip[2] = 200
    ip.to_string.should eq "192.168.200.0/24"
  end

  describe "#allocate" do
    it "should allocate a new ip from the current subnet" do
      ip = Subnet::IPv4.new("10.0.0.0/24")
      ip1 = ip.allocate
      ip2 = ip.allocate
      ip3 = ip.allocate
      ip1.try &.to_string.should eq "10.0.0.1/24"
      ip2.try &.to_string.should eq "10.0.0.2/24"
      ip3.try &.to_string.should eq "10.0.0.3/24"
    end

    it "should be able to skip addresses" do
      ip = Subnet::IPv4.new("10.0.0.0/24")
      ip1 = ip.allocate(2)
      ip1.try &.to_string.should eq "10.0.0.3/24"
    end

    it "should return nil when out of addresses" do
      ip = Subnet::IPv4.new("10.0.0.0/30")
      ip.allocate(3)
      ip.allocate.should be_nil
    end
  end
end
