require "./subnet/version"
require "./subnet/ipv4"
require "./subnet/ipv6"

# TODO: Write documentation for `Subnet`
module Subnet
  # Parse the argument string to create a new
  # IPv4, IPv6 or Mapped IP object
  #
  # ```
  # ip = Subnet.parse 167837953 # 10.1.1.1
  # ip = Subnet.parse "172.16.10.1/24"
  # ip6 = Subnet.parse "2001:db8::8:800:200c:417a/64"
  # ip_mapped = Subnet.parse "::ffff:172.16.10.1/128"
  # ```
  #
  # All the object created will be instances of the
  # correct class:
  #
  # ```
  # ip.class
  # # => Subnet::IPv4
  # ip6.class
  # # => Subnet::IPv6
  # ip_mapped.class
  # # => Subnet::IPv6::Mapped
  # ```
  def self.parse(str) : Subnet
    # Check if an int was passed
    if str.is_a? Number
      return Subnet::IPv4.new(ntoa(str))
    end

    case str
    when /:.+\./
      Subnet::IPv6::Mapped.new(str)
    when /\./
      Subnet::IPv4.new(str)
    when /:/
      Subnet::IPv6.new(str)
    else
      raise ArgumentError.new("Unknown IP Address #{str}")
    end
  end

  # Converts a unit32 to IPv4
  #
  # ```
  # Subnet::ntoa(167837953)
  #   # => "10.1.1.1"
  # ```
  def self.ntoa(uint)
    unless uint.is_a? Number && uint <= 0xffffffff && uint >= 0
      raise ArgumentError.new("not a long integer: #{uint.inspect}")
    end

    ret = [] of UInt8 | UInt16 | UInt32 | UInt64 | Int32 | Int64 | BigInt
    4.times do
      ret.unshift(uint & 0xff)
      uint >>= 8
    end
    ret.join('.')
  end

  # True if the object is an IPv4 address
  #
  # ```
  # ip = Subnet.parse("192.168.10.100/24")
  #
  # ip.ipv4?
  # # => true
  # ```
  def ipv4?
    self.is_a? Subnet::IPv4
  end

  #
  # True if the object is an IPv6 address
  #
  # ```
  # ip = Subnet.parse("192.168.10.100/24")
  #
  # ip.ipv6?
  # # => false
  # ```
  def ipv6?
    self.is_a? Subnet::IPv6
  end

  # Checks if the given string is either a valid IP, either a valid IPv4 subnet
  #
  # Example:
  #
  # ```
  # Subnet::valid? "10.0.0.0/24"
  #   # => true
  #
  # Subnet::valid? "2002::1"
  #   # => true
  #
  # Subnet::valid? "10.0.0.256"
  #   # => false
  #
  # Subnet::valid? "10.0.0.0/999"
  #   # => false
  # ```
  def self.valid?(addr)
    valid_ip?(addr) || valid_ipv4_subnet?(addr) || valid_ipv6_subnet?(addr)
  end

  # Checks if the given string is a valid IP address,
  # either IPv4 or IPv6
  #
  # Example:
  #
  # ```
  # Subnet::valid_ip? "2002::1"
  #   # => true
  #
  # Subnet::valid_ip? "10.0.0.256"
  #   # => false
  # ```
  def self.valid_ip?(addr)
    valid_ipv4?(addr) || valid_ipv6?(addr)
  end

  # Checks if the given string is a valid IPv4 subnet
  #
  # Example:
  #
  # ```
  # Subnet::valid_ipv4_subnet? "10.0.0.0/24"
  #   # => true
  #
  # Subnet::valid_ipv4_subnet? "10.0.0.0/255.255.255.0"
  #   # => true
  #
  # Subnet::valid_ipv4_subnet? "10.0.0.0/64"
  #   # => false
  # ```
  def self.valid_ipv4_subnet?(addr)
    ip, netmask = addr.split('/')

    valid_ipv4?(ip) && (!(netmask =~ /\A([12]?\d|3[0-2])\z/).nil? || valid_ipv4_netmask?(netmask))
  end

  # Checks if the given string is a valid IPv6 subnet
  #
  # Example:
  #
  # ```
  # Subnet::valid_ipv6_subnet? "::/0"
  #   # => true
  #
  # Subnet::valid_ipv6_subnet? "dead:beef:cafe:babe::/64"
  #   # => true
  #
  # Subnet::valid_ipv6_subnet? "2001::1/129"
  #   # => false
  # ```
  def self.valid_ipv6_subnet?(addr)
    ip, netmask = addr.split('/')

    netmask = netmask.to_i(10)

    valid_ipv6?(ip) && netmask >= 0 && netmask <= 128
  rescue ArgumentError
    false
  end

  # Checks if the given string is a valid IPv4 address
  #
  # Example:
  #
  # ```
  # Subnet::valid_ipv4? "2002::1"
  #   # => false
  #
  # Subnet::valid_ipv4? "172.16.10.1"
  #   # => true
  # ```
  def self.valid_ipv4?(addr)
    if /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\Z/ =~ addr
      return $~.captures.all? { |i| i.to_i < 256 unless i.nil? }
    end
    false
  end

  # Checks if the argument is a valid IPv4 netmask
  # expressed in dotted decimal format.
  #
  # ```
  # Subnet.valid_ipv4_netmask? "255.255.0.0"
  # # => true
  # ```
  def self.valid_ipv4_netmask?(addr)
    arr = addr.split(".").map { |i| i.to_u8 }
    bin = Slice.new(arr.to_unsafe, arr.size).hexstring.to_u32(16).to_s(2)
    bits = bin.scan(/01/)
    bits.empty? && valid_ipv4?(addr)
  rescue
    return false
  end

  # Checks if the given string is a valid IPv6 address
  #
  # Example:
  #
  # ```
  # Subnet::valid_ipv6? "2002::1"
  #   # => true
  #
  # Subnet::valid_ipv6? "2002::DEAD::BEEF"
  #   # => false
  # ```
  def self.valid_ipv6?(addr)
    # https://gist.github.com/cpetschnig/294476
    # http://forums.intermapper.com/viewtopic.php?t=452
    return true if /^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/ =~ addr
    false
  end

  # Deprecate method
  # :nodoc:
  def self.deprecate(message = nil)
    message ||= "You are using deprecated behavior which will be removed from the next major or minor release."
    warn("DEPRECATION WARNING: #{message}")
  end

  def self.new(value : JSON::PullParser) : Subnet
    Subnet.parse(value.read_string)
  end

  def to_json(json : JSON::Builder)
    json.string(to_string)
  end
end
