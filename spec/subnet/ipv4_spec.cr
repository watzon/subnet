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

IP = Subnet::IPv4.new("172.16.10.1/24")
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
  "10.32.0.1" => ["10.32.0.253", 253],
  "192.0.0.0" => ["192.1.255.255", 131072],
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
  end

  it "should have correct attributes" do
    VALID_IPV4.each do |(arg, attr)|
      ip = Subnet::IPv4.new(arg)
      ip.address.should eq attr.first
      ip.prefix.to_s.should eq attr.last
    end
  end

  it "should have an octet" do
    ip = Subnet::IPv4.new("10.1.2.3/8")
    ip.octets.should eq [10, 1, 2, 3]
  end

  it "should output binary data" do
    IP.data.should eq StaticArray[172, 16, 10, 1]
  end

  it "should convert to a string in cannonical form" do
    VALID_IPV4.each do |(arg, attr)|
      ip = Subnet::IPv4.new(arg)
      ip.to_string.should eq attr.join('/')
    end
  end

  it "should convert to a string in normal form" do
    VALID_IPV4.each do |(arg, attr)|
      ip = Subnet::IPv4.new(arg)
      ip.to_s.should eq attr.first
    end
  end

  it "should have a valid netmask" do
    NETMASK_VALUES.each do |(addr, mask)|
      ip = Subnet::IPv4.new(addr)
      ip.netmask.should eq mask
    end
  end

  it "should convert to u32" do
    DECIMAL_VALUES.each do |(addr, int)|
      ip = Subnet::IPv4.new(addr)
      ip.to_u32.should eq int
    end
  end

  it "should convert to a hex value" do
    HEX_VALUES.each do |(addr, hex)|
      ip = Subnet::IPv4.new(addr)
      ip.hexstring.should eq hex
    end
  end

  it "should detect network addresses" do
    NETWORK.network?.should be_true
    IP.network?.should be_false
  end

  it "should detect one address network" do
    network = Subnet::IPv4.new("172.16.10.1/32")
    network.network?.should be_false
  end

  it "should return the broadcast address" do
    BROADCAST.each do |(addr, bcast)|
      ip = Subnet::IPv4.new(addr)
      ip.broadcast.should be_a Subnet::IPv4
      ip.broadcast.to_string.should eq bcast
    end
  end

  it "should return the network address" do
    NETWORKS.each do |(addr, net)|
      ip = Subnet::IPv4.new(addr)
      ip.network.should be_a Subnet::IPv4
      ip.network.to_string.should eq net
    end
  end

  it "should return a bit string representing the address" do
    ip = Subnet::IPv4.new("127.0.0.1")
    ip.bits.should eq "01111111000000000000000000000001"
  end
end
