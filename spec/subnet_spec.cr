require "./spec_helper"

describe Subnet do
  describe ".parse" do
    it "should parse an IPv4 address" do
      ip = Subnet.parse("172.16.10.1/24")
      ip.should be_a Subnet::IPv4
      ip.to_string.should eq "172.16.10.1/24"
    end

    it "should parse an IPv6 address" do
      ip = Subnet.parse("2001:db8::8:800:200c:417a/64")
      ip.should be_a Subnet::IPv6
      ip.to_string.should eq "2001:db8::8:800:200c:417a/64"
    end

    it "should parse an IPv6 mapped address" do
      ip = Subnet.parse("::ffff:172.16.10.1/128")
      ip.should be_a Subnet::IPv6::Mapped
      ip.to_string.should eq "::ffff:172.16.10.1/128"
    end

    it "should parse an integer as IPv4" do
      ip = Subnet.parse(167837953)
      ip.should be_a Subnet::IPv4
      ip.to_s.should eq "10.1.1.1"
    end

    it "should raise for invalid address" do
      expect_raises(ArgumentError) do
        Subnet.parse("invalid")
      end
    end
  end

  describe ".ntoa" do
    it "should convert an integer to dotted decimal" do
      Subnet.ntoa(167837953).should eq "10.1.1.1"
      Subnet.ntoa(0).should eq "0.0.0.0"
      Subnet.ntoa(0xFFFFFFFF).should eq "255.255.255.255"
    end

    it "should raise for invalid integers" do
      expect_raises(ArgumentError) do
        Subnet.ntoa(-1)
      end

      expect_raises(ArgumentError) do
        Subnet.ntoa(0x100000000)
      end
    end
  end

  describe ".valid?" do
    it "should return true for valid IPv4 addresses" do
      Subnet.valid?("10.0.0.0/24").should be_true
      Subnet.valid?("192.168.1.1").should be_true
    end

    it "should return true for valid IPv6 addresses" do
      Subnet.valid?("2002::1").should be_true
      Subnet.valid?("::/0").should be_true
    end

    it "should return false for invalid addresses" do
      Subnet.valid?("10.0.0.256").should be_false
      Subnet.valid?("10.0.0.0/999").should be_false
    end
  end

  describe ".valid_ip?" do
    it "should validate IPv4 addresses" do
      Subnet.valid_ip?("172.16.10.1").should be_true
      Subnet.valid_ip?("10.0.0.256").should be_false
    end

    it "should validate IPv6 addresses" do
      Subnet.valid_ip?("2002::1").should be_true
      Subnet.valid_ip?("2002::DEAD::BEEF").should be_false
    end
  end

  describe ".valid_ipv4?" do
    it "should return true for valid IPv4 addresses" do
      Subnet.valid_ipv4?("172.16.10.1").should be_true
      Subnet.valid_ipv4?("0.0.0.0").should be_true
      Subnet.valid_ipv4?("255.255.255.255").should be_true
    end

    it "should return false for invalid IPv4 addresses" do
      Subnet.valid_ipv4?("10.0.0.256").should be_false
      Subnet.valid_ipv4?("10.0.0").should be_false
      Subnet.valid_ipv4?("2002::1").should be_false
    end
  end

  describe ".valid_ipv6?" do
    it "should return true for valid IPv6 addresses" do
      Subnet.valid_ipv6?("2002::1").should be_true
      Subnet.valid_ipv6?("::1").should be_true
      Subnet.valid_ipv6?("::").should be_true
    end

    it "should return false for invalid IPv6 addresses" do
      Subnet.valid_ipv6?("2002::DEAD::BEEF").should be_false
      Subnet.valid_ipv6?("172.16.10.1").should be_false
    end
  end

  describe ".valid_ipv4_netmask?" do
    it "should return true for valid netmasks" do
      Subnet.valid_ipv4_netmask?("255.255.255.0").should be_true
      Subnet.valid_ipv4_netmask?("255.255.0.0").should be_true
      Subnet.valid_ipv4_netmask?("255.0.0.0").should be_true
      Subnet.valid_ipv4_netmask?("0.0.0.0").should be_true
    end

    it "should return false for invalid netmasks" do
      Subnet.valid_ipv4_netmask?("255.255.0.255").should be_false
      Subnet.valid_ipv4_netmask?("invalid").should be_false
    end
  end

  describe ".valid_ipv4_subnet?" do
    it "should return true for valid subnets" do
      Subnet.valid_ipv4_subnet?("10.0.0.0/24").should be_true
      Subnet.valid_ipv4_subnet?("10.0.0.0/255.255.255.0").should be_true
    end

    it "should return false for invalid subnets" do
      Subnet.valid_ipv4_subnet?("10.0.0.0/64").should be_false
      Subnet.valid_ipv4_subnet?("10.0.0.256/24").should be_false
    end
  end

  describe ".valid_ipv6_subnet?" do
    it "should return true for valid subnets" do
      Subnet.valid_ipv6_subnet?("::/0").should be_true
      Subnet.valid_ipv6_subnet?("dead:beef:cafe:babe::/64").should be_true
    end

    it "should return false for invalid subnets" do
      Subnet.valid_ipv6_subnet?("2001::1/129").should be_false
    end
  end

  describe "#ipv4?" do
    it "should return true for IPv4 addresses" do
      ip = Subnet.parse("192.168.10.100/24")
      ip.ipv4?.should be_true
    end

    it "should return false for IPv6 addresses" do
      ip = Subnet.parse("2001:db8::1/64")
      ip.ipv4?.should be_false
    end
  end

  describe "#ipv6?" do
    it "should return true for IPv6 addresses" do
      ip = Subnet.parse("2001:db8::1/64")
      ip.ipv6?.should be_true
    end

    it "should return false for IPv4 addresses" do
      ip = Subnet.parse("192.168.10.100/24")
      ip.ipv6?.should be_false
    end
  end

  describe "JSON serialization" do
    it "should serialize IPv4 to JSON" do
      ip = Subnet::IPv4.new("172.16.10.1/24")
      json = JSON.build { |builder| ip.to_json(builder) }
      json.should eq "\"172.16.10.1/24\""
    end

    it "should serialize IPv6 to JSON" do
      ip = Subnet::IPv6.new("2001:db8::8:800:200c:417a/64")
      json = JSON.build { |builder| ip.to_json(builder) }
      json.should eq "\"2001:db8::8:800:200c:417a/64\""
    end

    it "should deserialize IPv4 from JSON" do
      json = JSON::PullParser.new("\"172.16.10.1/24\"")
      ip = Subnet::IPv4.new(json)
      ip.to_string.should eq "172.16.10.1/24"
    end

    it "should deserialize IPv6 from JSON" do
      json = JSON::PullParser.new("\"2001:db8::8:800:200c:417a/64\"")
      ip = Subnet::IPv6.new(json)
      ip.to_string.should eq "2001:db8::8:800:200c:417a/64"
    end
  end
end
