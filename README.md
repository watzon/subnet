# Subnet

[![Crystal Version](https://img.shields.io/badge/crystal-%3E%3D1.0.0-black)](https://crystal-lang.org)
[![GitHub release](https://img.shields.io/github/v/release/watzon/subnet)](https://github.com/watzon/subnet/releases)
[![License](https://img.shields.io/github/license/watzon/subnet)](LICENSE)

A Crystal library for working with IPv4 and IPv6 addresses.

Subnet provides a complete set of methods to handle IP addresses for any need, from simple scripting to full network design. It features a clean OO interface, comprehensive IPv4/IPv6 support, and efficient native `UInt128` operations for IPv6.

Based on the Ruby [IPAddress](https://github.com/ipaddress-gem/ipaddress) gem.

## Table of Contents

- [Install](#install)
- [Usage](#usage)
  - [IPv4](#ipv4)
  - [IPv6](#ipv6)
  - [Network Operations](#network-operations)
- [API](#api)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [License](#license)

## Install

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  subnet:
    github: watzon/subnet
    version: ~> 0.2.0
```

Run `shards install`.

## Usage

```crystal
require "subnet"
```

### IPv4

Create and manipulate IPv4 addresses:

```crystal
# Create an IPv4 address
ip = Subnet::IPv4.new("172.16.10.1/24")

# Or use the universal parser
ip = Subnet.parse("172.16.10.1/24")

# Access properties
ip.address    # => "172.16.10.1"
ip.prefix     # => 24
ip.netmask    # => "255.255.255.0"
ip.octets     # => [172, 16, 10, 1]
ip.to_u32     # => 2886732289

# Network calculations
ip.network.to_string    # => "172.16.10.0/24"
ip.broadcast.to_string  # => "172.16.10.255/24"
ip.first.to_s           # => "172.16.10.1"
ip.last.to_s            # => "172.16.10.254"

# Check address types
ip.private?     # => true
ip.loopback?    # => false
ip.network?     # => false

# Iterate over addresses
ip.each_host { |host| puts host }
```

### IPv6

Full IPv6 support with native `UInt128` operations:

```crystal
ip6 = Subnet::IPv6.new("2001:db8::8:800:200c:417a/64")

ip6.address     # => "2001:0db8:0000:0000:0008:0800:200c:417a"
ip6.compressed  # => "2001:db8::8:800:200c:417a"
ip6.to_u128     # => 42540766411282592856906245548098208122 (UInt128)

# Special addresses
loopback = Subnet::IPv6::Loopback.new
loopback.to_string  # => "::1/128"

# IPv4-mapped addresses
mapped = Subnet::IPv6::Mapped.new("::ffff:172.16.10.1/128")
mapped.ipv4.address  # => "172.16.10.1"
```

### Network Operations

Subnet provides powerful network manipulation:

```crystal
# Subnetting - divide a network
network = Subnet::IPv4.new("172.16.10.0/24")
subnets = network.split(4)
subnets.map(&.to_string)
# => ["172.16.10.0/26", "172.16.10.64/26", 
#     "172.16.10.128/26", "172.16.10.192/26"]

# Supernetting - combine networks
network.supernet(23).to_string  # => "172.16.10.0/23"

# Summarization - find optimal supernet
ip1 = Subnet::IPv4.new("172.16.10.0/24")
ip2 = Subnet::IPv4.new("172.16.11.0/24")
Subnet::IPv4.summarize(ip1, ip2).map(&.to_string)
# => ["172.16.10.0/23"]

# Check inclusion
network.includes?(Subnet::IPv4.new("172.16.10.50/32"))  # => true

# Allocate addresses sequentially
ip = Subnet::IPv4.new("10.0.0.0/24")
ip.allocate  # => "10.0.0.1/24"
ip.allocate  # => "10.0.0.2/24"
```

## API

### Subnet Module

- `Subnet.parse(address)` - Parse IPv4, IPv6, or mapped addresses
- `Subnet.valid?(address)` - Check if address is valid
- `Subnet.valid_ipv4?(address)` - Check IPv4 validity
- `Subnet.valid_ipv6?(address)` - Check IPv6 validity

### Subnet::IPv4

**Creation:**
- `.new(address)` - Create from string (e.g., "192.168.1.1/24")
- `.parse_u32(int, prefix)` - Create from 32-bit integer
- `.parse_data(bytes, prefix)` - Create from byte array
- `.parse_classful(address)` - Create with classful prefix
- `.extract(string)` - Extract IPv4 from string

**Properties:**
- `#address` - Address string
- `#prefix` - Prefix object
- `#netmask` - Netmask string
- `#octets` - Array of octets
- `#to_u32` / `#to_i` - 32-bit integer
- `#bits` - Binary string
- `#hexstring` - Hex string

**Network:**
- `#network` - Network address
- `#broadcast` - Broadcast address
- `#first` / `#last` - First/last host
- `#size` - Number of addresses
- `#hosts` - Array of host addresses
- `#includes?(other)` - Check if includes address
- `#each` / `#each_host` - Iterate addresses

**Operations:**
- `#subnet(prefix)` - Subnet to new prefix
- `#split(count)` - Split into N subnets
- `#supernet(prefix)` - Create supernet
- `#allocate(skip)` - Allocate next address
- `.summarize(*addresses)` - Summarize addresses

**Checks:**
- `#private?` / `#loopback?` / `#multicast?` / `#link_local?`
- `#network?` - Is network address
- `#a?` / `#b?` / `#c?` - Classful checks

### Subnet::IPv6

Similar interface to IPv4, with additions:

- `#to_u128` - 128-bit integer (UInt128)
- `#compressed` - Compressed string
- `#groups` / `#hex_groups` - 16-bit groups
- `#unspecified?` / `#loopback?` / `#mapped?`
- `#link_local?` / `#unique_local?`
- `.expand(address)` / `.compress(address)` - String utilities
- `.parse_u128(int, prefix)` - Create from UInt128
- `.parse_hex(hex, prefix)` - Create from hex string

**Subclasses:**
- `Subnet::IPv6::Loopback` - Loopback address (::1)
- `Subnet::IPv6::Unspecified` - Unspecified address (::)
- `Subnet::IPv6::Mapped` - IPv4-mapped address (::ffff:x.x.x.x)

## Maintainers

- [Chris Watson](https://github.com/watzon)

## Contributing

1. Fork it ([https://github.com/watzon/subnet/fork](https://github.com/watzon/subnet/fork))
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Bug reports and pull requests are welcome on GitHub.

## License

[MIT](LICENSE) - Chris Watson
