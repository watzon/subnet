require "../spec_helper"

NETMASK0  = "0.0.0.0"
NETMASK8  = "255.0.0.0"
NETMASK16 = "255.255.0.0"
NETMASK24 = "255.255.255.0"
NETMASK30 = "255.255.255.252"
NETMASKS  = [NETMASK0, NETMASK8, NETMASK16, NETMASK24, NETMASK30]

PREFIX_HASH = {
  "0.0.0.0"         => 0,
  "255.0.0.0"       => 8,
  "255.255.0.0"     => 16,
  "255.255.255.0"   => 24,
  "255.255.255.252" => 30,
}

OCTETS_HASH = {
  Bytes[0, 0, 0, 0]         => 0,
  Bytes[255, 0, 0, 0]       => 8,
  Bytes[255, 255, 0, 0]     => 16,
  Bytes[255, 255, 255, 0]   => 24,
  Bytes[255, 255, 255, 252] => 30,
}

U32_HASH = {
   0 => 0,
   8 => 4278190080,
  16 => 4294901760,
  24 => 4294967040,
  30 => 4294967292,
}

describe Subnet::Prefix do
  describe Subnet::Prefix32 do
    it "should have a prefix" do
      PREFIX_HASH.values.each do |num|
        prefix = Subnet::Prefix32.new(num)
        num.should eq prefix.prefix
      end
    end

    it "should parse the netmask" do
      PREFIX_HASH.each do |(netmask, num)|
        prefix = Subnet::Prefix32.parse_netmask(netmask)
        num.should eq prefix.prefix
        prefix.should be_a Subnet::Prefix32
      end
    end

    it "should convert prefix to ip" do
      PREFIX_HASH.each do |(netmask, num)|
        prefix = Subnet::Prefix32.new(num)
        netmask.should eq prefix.to_ip
      end
    end

    it "should convert prefix to string" do
      prefix = Subnet::Prefix32.new(8)
      prefix.to_s.should eq "8"
    end

    it "should convert prefix to bits" do
      prefix = Subnet::Prefix32.new(16)
      str = "1" * 16 + "0" * 16
      prefix.bits.should eq str
    end

    it "should convert prefix to u32" do
      U32_HASH.each do |(num, u32)|
        Subnet::Prefix32.new(num).to_u32.should eq u32
      end
    end

    it "should add two prefixes" do
      p1 = Subnet::Prefix32.new(8)
      p2 = Subnet::Prefix32.new(10)
      (p1 + p2).should eq 18
      (p1 + 4).should eq 12
    end

    it "should subtract two prefixes" do
      p1 = Subnet::Prefix32.new(8)
      p2 = Subnet::Prefix32.new(24)
      (p1 - p2).should eq 16
      (p2 - p1).should eq 16
      (p2 - 4).should eq 20
    end

    it "should fail to initialize with prefix over 32" do
      expect_raises(ArgumentError) do
        Subnet::Prefix32.new(33)
      end
    end

    it "should initialize a new prefix" do
      Subnet::Prefix32.new(8).should be_a Subnet::Prefix32
    end

    it "should have octets" do
      OCTETS_HASH.each do |(arr, pref)|
        prefix = Subnet::Prefix32.new(pref)
        prefix.octets.should eq arr
      end
    end

    it "should select octet index with #[]" do
      OCTETS_HASH.each do |(arr, pref)|
        prefix = Subnet::Prefix32.new(pref)
        arr.each_with_index do |oct, index|
          prefix[index].should eq oct
        end
      end
    end

    it "should return a hostmask" do
      prefix = Subnet::Prefix32.new(8)
      prefix.hostmask.should eq "0.255.255.255"
    end
  end
end
