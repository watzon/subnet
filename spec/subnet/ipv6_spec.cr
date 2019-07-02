require "big"
require "../subnet_spec"

IPV6_COMPRESS_ADDR = {
  "2001:db8:0000:0000:0008:0800:200c:417a" => "2001:db8::8:800:200c:417a",
  "2001:db8:0:0:8:800:200c:417a"           => "2001:db8::8:800:200c:417a",
  "ff01:0:0:0:0:0:0:101"                   => "ff01::101",
  "0:0:0:0:0:0:0:1"                        => "::1",
  "0:0:0:0:0:0:0:0"                        => "::",
}

VALID_IPV6 = { # Kindly taken from the python IPy library
  "FEDC:BA98:7654:3210:FEDC:BA98:7654:3210" => BigInt.new("338770000845734292534325025077361652240"),
  "1080:0000:0000:0000:0008:0800:200C:417A" => BigInt.new("21932261930451111902915077091070067066"),
  "1080:0:0:0:8:800:200C:417A"              => BigInt.new("21932261930451111902915077091070067066"),
  "1080:0::8:800:200C:417A"                 => BigInt.new("21932261930451111902915077091070067066"),
  "1080::8:800:200C:417A"                   => BigInt.new("21932261930451111902915077091070067066"),
  "FF01:0:0:0:0:0:0:43"                     => BigInt.new("338958331222012082418099330867817087043"),
  "FF01:0:0::0:0:43"                        => BigInt.new("338958331222012082418099330867817087043"),
  "FF01::43"                                => BigInt.new("338958331222012082418099330867817087043"),
  "0:0:0:0:0:0:0:1"                         => 1,
  "0:0:0::0:0:1"                            => 1,
  "::1"                                     => 1,
  "0:0:0:0:0:0:0:0"                         => 0,
  "0:0:0::0:0:0"                            => 0,
  "::"                                      => 0,
}

INVALID_IPV6 = [
  ":1:2:3:4:5:6:7",
  ":1:2:3:4:5:6:7",
  "2002:516:2:200",
  "dd",
]

IPV6_NETWORKS = {
  "2001:db8:1:1:1:1:1:1/32" => "2001:db8::/32",
  "2001:db8:1:1:1:1:1::/32" => "2001:db8::/32",
  "2001:db8::1/64"          => "2001:db8::/64",
}

IPV6         = Subnet::IPv6.new "2001:db8::8:800:200c:417a/64"
IPV6_NETWORK = Subnet::IPv6.new "2001:db8:8:800::/64"
IPV6_ARR     = [8193, 3512, 0, 0, 8, 2048, 8204, 16762]
IPV6_HEX     = "20010db80000000000080800200c417a"

IPV6_LINK_LOCAL = [
  "fe80::",
  "fe80::1",
  "fe80::208:74ff:feda:625c",
  "fe80::/64",
  "fe80::/65",
]

IPV6_NOT_LINK_LOCAL = [
  "::",
  "::1",
  "ff80:03:02:01::",
  "2001:db8::8:800:200c:417a",
  # TODO: Figure out if this is really not a link local address
  # "fe80::/63",
]

IPV6_UNIQUE_LOCAL = [
  "fc00::/7",
  "fc00::/8",
  "fd00::/8",
  "fd12:3456:789a:1::1",
  "fd12:3456:789a:1::/64",
  "fc00::1",
]

IPV6_NOT_UNIQUE_LOCAL = [
  "fc00::/6",
  "::",
  "::1",
  "fe80::",
  "fe80::1",
  "fe80::/64",
]

describe Subnet::IPv6 do
  describe "#address" do
    it "should return the address" do
      IPV6.address.should eq "2001:0db8:0000:0000:0008:0800:200c:417a"
    end
  end

  describe "#initialize" do
    it "should create a new instance of IPv6" do
      IPV6.should be_a Subnet::IPv6
    end

    it "should raise with IPv6 mapped address" do
      expect_raises(ArgumentError) do
        Subnet::IPv6.new("::10.1.1.1")
      end
    end

    it "should raise with invalid address" do
      INVALID_IPV6.each do |ip|
        expect_raises(ArgumentError) do
          Subnet::IPv6.new(ip)
        end
      end
    end

    it "should return have a valid prefix" do
      IPV6.prefix.should eq 64
    end
  end

  describe "#groups" do
    it "should return the address as groups of int64" do
      IPV6.groups.should eq IPV6_ARR
    end
  end

  describe "#hex_groups" do
    it "should return the address as hexidecimal groups" do
      arr = "2001:0db8:0000:0000:0008:0800:200c:417a".split(":")
      IPV6.hex_groups.should eq arr
    end
  end

  describe "#to_i" do
    it "should return the address as an integer" do
      VALID_IPV6.each do |(ip, num)|
        Subnet::IPv6.new(ip).to_i.should eq num
      end
    end

    pending "should be a UInt128" do
      IPV6.to_i.should be_a UInt128
    end
  end

  describe "#bits" do
    it "should return the address as a binary string" do
      bits = "0010000000000001000011011011100000000000000000000\
      000000000000000000000000000100000001000000000000010000\
      0000011000100000101111010"
      IPV6.bits.should eq bits
    end
  end

  describe "#prefix=" do
    it "should set the prefix" do
      ip = Subnet::IPv6.new("2001:db8::8:800:200c:417a")
      ip.prefix.should eq 128
      ip.prefix = 64
      ip.prefix.should eq 64
      ip.to_string.should eq "2001:db8::8:800:200c:417a/64"
    end
  end

  describe "#mapped?" do
    it "should check if a ip is mapped" do
      IPV6.mapped?.should be_false
      ip6 = Subnet::IPv6.new("::ffff:1234:5678")
      ip6.mapped?.should be_true
    end
  end

  describe "#literal" do
    it "should reuturn a literal representation of the ip" do
      str = "2001-0db8-0000-0000-0008-0800-200c-417a.ipv6-literal.net"
      IPV6.literal.should eq str
    end
  end

  describe "#[]" do
    it "should return the int64 at the requested index" do
      IPV6_ARR.each_with_index do |val, index|
        IPV6[index].should eq val
      end
    end
  end

  describe "#ipv4?" do
    it "should check if the address is a ipv4" do
      IPV6.ipv4?.should be_false
    end
  end

  describe "#ipv6?" do
    it "should check if the address is a ipv6" do
      IPV6.ipv6?.should be_true
    end
  end

  describe "#network?" do
    it "should check if the address is a network address" do
      IPV6_NETWORK.network?.should be_true
      IPV6.network?.should be_false
    end
  end

  describe "#network_u128" do
    it "should return a 128 bit representation of the network address" do
      num = BigInt.new("42540766411282592856903984951653826560")
      IPV6.network_u128.should eq num
    end
  end

  describe "#broadcast_u128" do
    it "should return a 128 bit representation of the network address" do
      num = BigInt.new("42540766411282592875350729025363378175")
      IPV6.broadcast_u128.should eq num
    end
  end

  describe "#size" do
    it "should return the number of ip addresses in the network" do
      ip = Subnet::IPv6.new("2001:db8::8:800:200c:417a/64")
      ip.size.should eq 2.to_big_i ** 64.to_big_i

      ip = Subnet::IPv6.new("2001:db8::8:800:200c:417a/32")
      ip.size.should eq 2.to_big_i ** 96.to_big_i

      ip = Subnet::IPv6.new("2001:db8::8:800:200c:417a/120")
      ip.size.should eq 2.to_big_i ** 8.to_big_i

      ip = Subnet::IPv6.new("2001:db8::8:800:200c:417a/124")
      ip.size.should eq 2.to_big_i ** 4.to_big_i
    end
  end

  describe "#includes?" do
    it "should return true for the same address" do
      IPV6.includes?(IPV6).should be_true
    end

    it "should return true if a network includes an address" do
      ip1 = Subnet::IPv6.new "2001:db8::8:800:200c:417a/128"
      ip2 = Subnet::IPv6.new "2001:db8::8:800:200c:0/64"
      ip3 = Subnet::IPv6.new "2001:db8::8:800:200c:1/128"

      [ip1, ip2, ip3].each do |ip|
        IPV6.includes?(ip).should be_true
      end
    end

    it "should return false if a network doesn't include an address" do
      ip1 = Subnet::IPv6.new "2001:db8::8:800:200c:417a/46"
      ip2 = Subnet::IPv6.new "2001:db8:1::8:800:200c:417a/64"
      ip3 = Subnet::IPv6.new "2001:db8:1::8:800:200c:417a/76"

      [ip1, ip2, ip3].each do |ip|
        IPV6.includes?(ip).should be_false
      end
    end
  end

  describe "#hexstring" do
    it "should return a hexidecimal representation of the address" do
      IPV6.hexstring.should eq IPV6_HEX
    end
  end

  describe "#to_s" do
    it "should return a prefixless string" do
      IPV6.to_s.should eq "2001:db8::8:800:200c:417a"
    end
  end

  describe "#to_string" do
    it "should return a prefixed string" do
      IPV6.to_string.should eq "2001:db8::8:800:200c:417a/64"
    end
  end

  describe "#to_s_uncompressed" do
    it "should return an uncompressed string representation of the address" do
      str = "2001:0db8:0000:0000:0008:0800:200c:417a/64"
      IPV6.to_string_uncompressed.should eq str
    end
  end

  describe "#data" do
    it "should return the address in network byte order format" do
      str = " \001\r\270\000\000\000\000\000\b\b\000 \fAz"
      IPV6.data.should eq str
    end
  end

  describe "#reverse" do
    it "should return the address in reversed (arpa) format" do
      str = "f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.5.0.5.0.e.f.f.3.ip6.arpa"
      Subnet::IPv6.new("3ffe:505:2::f").reverse.should eq str
    end
  end

  describe "#compressed" do
    it "should return the compressed representation of the address" do
      Subnet::IPv6.new("1:1:1:0:0:0:0:1").compressed.should eq "1:1:1::1"
      Subnet::IPv6.new("1:0:1:0:0:0:0:1").compressed.should eq "1:0:1::1"
      Subnet::IPv6.new("1:0:0:1:0:0:0:1").compressed.should eq "1:0:0:1::1"
      Subnet::IPv6.new("1:0:0:0:1:0:0:1").compressed.should eq "1::1:0:0:1"
      Subnet::IPv6.new("1:0:0:0:0:0:0:1").compressed.should eq "1::1"
    end
  end

  describe "#link_local" do
    it "should return true if the address is a link local address" do
      IPV6_LINK_LOCAL.each do |ip|
        Subnet::IPv6.new(ip).link_local?.should be_true
      end

      IPV6_NOT_LINK_LOCAL.each do |ip|
        Subnet::IPv6.new(ip).link_local?.should be_false
      end
    end
  end

  describe "#unique_local" do
    it "should return true if the address is a unique local address" do
      IPV6_UNIQUE_LOCAL.each do |ip|
        Subnet::IPv6.new(ip).unique_local?.should be_true
      end

      IPV6_NOT_UNIQUE_LOCAL.each do |ip|
        Subnet::IPv6.new(ip).unique_local?.should be_false
      end
    end
  end

  describe "#network" do
    it "should return a new ipv6 with the network number for the given ip" do
      IPV6_NETWORKS.each do |(addr, net)|
        ip = Subnet::IPv6.new(addr)
        ip.network.should be_a Subnet::IPv6
        ip.network.to_string.should eq net
      end
    end
  end

  describe "#each" do
    it "should iterate over every IP address in the given network" do
      ip = Subnet::IPv6.new("2001:db8::4/125")
      arr = [] of String
      ip.each { |i| arr << i.compressed }
      expected = ["2001:db8::", "2001:db8::1", "2001:db8::2",
                  "2001:db8::3", "2001:db8::4", "2001:db8::5",
                  "2001:db8::6", "2001:db8::7"]
      arr.should eq expected
    end
  end

  describe "#allocate" do
    it "should allocate the next address in the network" do
      ip = Subnet::IPv6.new("2001:db8::4/125")
      ip1 = ip.allocate
      ip2 = ip.allocate
      ip3 = ip.allocate
      ip1.try &.compressed.should eq "2001:db8::1"
      ip2.try &.compressed.should eq "2001:db8::2"
      ip3.try &.compressed.should eq "2001:db8::3"
    end

    it "should allow skipping addresses" do
      ip = Subnet::IPv6.new("2001:db8::4/125")
      ip1 = ip.allocate(2)
      ip1.try &.compressed.should eq "2001:db8::3"
    end

    it "should return nil on empty" do
      ip = Subnet::IPv6.new("2001:db8::4/125")
      ip.allocate(6)
      ip.allocate.should be_nil
    end
  end

  describe "comparison operators" do
    it "should work" do
      ip1 = Subnet::IPv6.new("2001:db8:1::1/64")
      ip2 = Subnet::IPv6.new("2001:db8:2::1/64")
      ip3 = Subnet::IPv6.new("2001:db8:1::2/64")
      ip4 = Subnet::IPv6.new("2001:db8:1::1/65")

      (ip2 > ip1).should be_true
      (ip1 > ip2).should be_false
      (ip2 < ip1).should be_false

      (ip2 > ip3).should be_true
      (ip2 < ip3).should be_false

      (ip1 < ip3).should be_true
      (ip1 > ip3).should be_false
      (ip3 < ip1).should be_false

      (ip1 == ip1).should be_true

      (ip1 < ip4).should be_true
      (ip1 > ip4).should be_false

      arr = ["2001:db8:1::1/64", "2001:db8:1::1/65",
             "2001:db8:1::2/64", "2001:db8:2::1/64"]
      [ip1, ip2, ip3, ip4].sort.map(&.to_string).should eq arr

      ip1 = Subnet::IPv6.new("::1")
      ip2 = Subnet::IPv4.new("127.0.0.1")

      (ip1 < ip2).should be_true
    end
  end

  describe ".expand" do
    it "should expand an ipv6 address in cannonical form" do
      compressed = "2001:db8:0:cd30::"
      expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000"
      Subnet::IPv6.expand(compressed).should eq expanded
      Subnet::IPv6.expand("2001:0db8:0::cd3").should_not eq expanded
      Subnet::IPv6.expand("2001:0db8::cd30").should_not eq expanded
      Subnet::IPv6.expand("2001:0db8::cd3").should_not eq expanded
    end
  end

  describe ".compress" do
    it "should compress an ipv6 address" do
      compressed = "2001:db8:0:cd30::"
      expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000"
      Subnet::IPv6.compress(expanded).should eq compressed
      Subnet::IPv6.compress("2001:0db8:0::cd3").should_not eq compressed
      Subnet::IPv6.compress("2001:0db8::cd30").should_not eq compressed
      Subnet::IPv6.compress("2001:0db8::cd3").should_not eq compressed
    end
  end

  describe ".parse_data" do
    it "should create a IPv6 object from a data string" do
      str = " \001\r\270\000\000\000\000\000\b\b\000 \fAz"
      ip = Subnet::IPv6.parse_data str
      ip.should be_a Subnet::IPv6
      ip.address.should eq "2001:0db8:0000:0000:0008:0800:200c:417a"
      ip.to_string.should eq "2001:db8::8:800:200c:417a/128"
    end
  end

  describe ".parse_u128" do
    it "should parse a u128 to a IPv6" do
      VALID_IPV6.each do |(ip, num)|
        Subnet::IPv6.parse_u128(num).to_s.should eq Subnet::IPv6.new(ip).to_s
      end
    end
  end

  describe ".parse_hex" do
    it "should parse a hexidecimal string to a IPv6" do
      Subnet::IPv6.parse_hex(IPV6_HEX, 64).to_s.should eq IPV6.to_s
    end
  end

  describe "#[]=" do
    it "should update the address group at index" do
      ip = Subnet::IPv6.new("2001:db8::8:800:200c:417a/64")
      ip[2] = 1234
      ip.to_string.should eq "2001:db8:4d2:0:8:800:200c:417a/64"
    end
  end
end
