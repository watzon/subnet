require "big"

module Subnet
  # The base class for `Prefix32` and `Prefix128` defining some
  # common methods that exist in both.
  abstract class Prefix
    include Comparable(Prefix | UInt8 | UInt32 | UInt64 | Int32 | Int64)

    property prefix : Int32

    # Create a new `Prefix`.
    def initialize(num)
      @prefix = num.to_i
    end

    # Convert the Prefix to a string.
    def to_s(io)
      io << @prefix.to_s
    end

    # Return this Prefix as an integer.
    def to_i
      @prefix
    end

    # Compare this Prefix to another.
    def <=>(other)
      @prefix <=> other.to_i
    end

    # Add this Prefix to another.
    def +(other)
      if other.is_a?(Number)
        @prefix + other
      else
        @prefix + other.prefix
      end
    end

    # Subtract another Prefix from this one.
    def -(other)
      if other.is_a?(Number)
        @prefix - other
      else
        (@prefix - other.prefix).abs
      end
    end
  end

  class Prefix32 < Prefix

    IN4MASK = 0xffffffff

    # Creates a new Prefix for 32 bit IPv4 Addresses.
    def initialize(num)
      num = num.to_i
      unless (0..32).includes?(num)
        raise ArgumentError.new("Prefix must be in range 0..32, got: #{num}")
      end
      super(num)
    end

    # Returns the length of the host portion of a
    # netmask.
    def host_prefix
      32 - @prefix
    end

    # Transforms the prefix into a string of bits
    # representing the netmask.
    def bits
      "%.32b" % to_u32
    end

    # Gives the prefix in IPv4 dotted decimal format,
    # i.e. the cannonical netmask we're all used to.
    def to_ip
      octets.join('.')
    end

    # An array of octets of the IPv4 dotted decimal format.
    def octets
      ("%08.64x" % bits.to_i64(2)).hexbytes
    end

    # Unsigned 32 bit number representing the prefix.
    #
    #   prefix = Subnet::Prefix32.new 24
    #
    #   prefix.to_u32
    #     #=> 4294967040
    def to_u32
      (IN4MASK >> host_prefix) << host_prefix
    end

    # Shortcut for the octets in dotted decimal
    # representation.
    def [](index)
      octets[index]
    end

    # The hostmask is the contrary of the subnet mask,
    # as it shows the bits that can change within the
    # hosts
    def hostmask
      hostmask_octets.join('.')
    end

    # Array of octets representing the hostmask
    def hostmask_octets
      octets = uninitialized UInt8[4]
      IO::ByteFormat::BigEndian.encode(~to_u32.to_u32, octets.to_slice)
      octets
    end

    # Creates a new prefix by parsing a netmask in
    # dotted decimal form.
    def self.parse_netmask(netmask)
      octets = netmask.is_a?(Indexable) ? netmask : netmask.split('.')
      raise "netmask must contain 4 octets" unless octets.size == 4
      octets = octets.map(&.to_u8)
      num = Slice.new(octets.to_unsafe, 4).hexstring.to_u32(16)
        .to_s(2).count("1")
      Prefix32.new(num)
    end
  end

  class Prefix128 < Prefix

    # Creates a new prefix object for 128 bit IPv6 addresses.
    def initialize(num = 128)
      num = num.to_i
      unless (0..128).includes?(num)
        raise ArgumentError.new("Prefix must be in range 0..128, got: #{num}")
      end
      super(num)
    end

    # Transforms the prefix into a string of bits
    # representing the netmask
    def bits
      "1" * @prefix + "0" * (128 - @prefix)
    end

    # Unsigned 128 bit decimal number representing
    # the prefix.
    def to_u128
      # TODO: Update this to use `UInt128` once support
      # for it is finished.
      bits.to_big_i(2)
    end

    def host_prefix
      128 - @prefix
    end
  end
end
