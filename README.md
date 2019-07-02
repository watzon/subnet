# Subnet

Subnet is a Crystal library designed to make the use of IPv4 and IPv6 addresses simple, powerful and enjoyable. It provides a complete set of methods to handle IP addresses for any need, from simple scripting to full network design.

Subnet is written with a full OO interface, and its code is easy to read, maintain and extend. The documentation is full of examples, to let you start being productive immediately.

This document provides a brief introduction to the library and examples of typical usage. You can check out the full documentation [here](https://watzon.github.io/subnet/).

# Table of Contents

- [Subnet](#Subnet)
- [Table of Contents](#Table-of-Contents)
  - [Installation](#Installation)
  - [IPv4](#IPv4)
    - [Create a new IPv4 address](#Create-a-new-IPv4-address)
    - [Handling IPv4 addresses](#Handling-IPv4-addresses)
    - [Changing netmask](#Changing-netmask)
    - [Working with networks, broadcasts, and addresses](#Working-with-networks-broadcasts-and-addresses)
      - [Networks](#Networks)
      - [Broadcast](#Broadcast)
    - [Addresses, ranges, and iterators](#Addresses-ranges-and-iterators)
  - [Contributing](#Contributing)
  - [Contributors](#Contributors)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     subnet:
       github: watzon/subnet
   ```

2. Run `shards install`

3. Require it in your project

```crystal
require "subnet"
```

## IPv4

The class `Subnet::IPv4` is used to handle IPv4 type addresses. This, and other classes, are almost 1/1 the same as the [IPAddress](https://github.com/ipaddress-gem/ipaddress) ruby gem which this was based off of.

### Create a new IPv4 address

Creating a IPv4 address is simple

```crystal
ip = Subnet::IPv4.new("172.16.10.1")
```

and supports prefixes.

```crystal
ip = Subnet::IPv4.new("172.16.10.1/24")
```

You can also use the somewhat easier

```crystal
ip = Subnet.parse("172.16.10.1/24")
```

which parses both IPv4 and IPv6 addresses. The result from this will be of type `Subnet` though and will only freely have the methods that both `Subnet::IPv4` and `Subnet::IPv6` share in common. For now to circumvent this you can do `.as(Subnet::IPv4)` or just use `IPv4.new`.

If you don't explicitly specify the prefix (or the subnet mask), Subnet will think you're dealing with host addresses and not with networks. Therefore, the default prefix will be `/32`, or `255.255.255.255`. For example:

```crystal
# let's declare an host address
host = Subnet::IPv4.new("10.1.1.1")

puts host.to_string
# => "10.1.1.1/32"
```

You can also parse a `UInt32` to create a new IPv4 object

```crystal
ip = IPv4.parse_u32(167837953)
puts ip.to_string
# => "10.1.1.1/32"
```

### Handling IPv4 addresses

Once created, you can obtain the attributes for an IPv4 object

```crystal
ip = Subnet::IPv4.new("172.16.10.1/24")

ip.address
# => "172.16.10.1"
ip.prefix
# => 24
```

If you need to retrieve the netmask in IPv4 format, you can use the `IPv4#netmask` method:

```crystal
ip.netmask
# => "255.255.255.0"
```

A special attribute, `IPv4#octets`, is available to get the four decimal octets from the IP address:

```crystal
ip.octets
# => [172, 16, 10, 1]
```

The shortcut method `IPv4#[]`, provides access to a given octet at the specified index:

```
ip[1]
# => 16
```

If you need to print out the IPv4 address in a canonical form, you can use `IPv4#to_string`:

```crystal
ip.to_string
# => "172.16.10.1/24"
```

`IPv4#to_s` is also available and prints the address without the prefix

```crystal
ip.to_s
# => "172.16.10.1"
```

### Changing netmask

You can set a new prefix (netmask) after creating an IPv4 object. For example

```
ip.prefix = 25

ip.to_string
# => "172.16.10.1/25"
```

If you need to use a netmask in IPv4 format, you can do so by using the `IPv4#netmask=` method

```crystal
ip.netmask = "255.255.255.252"

ip.to_string
# => "172.16.10.1/30"
```

### Working with networks, broadcasts, and addresses

Some very important topics in dealing with IP addresses are the concepts of `network` and `broadcast`, as well as the addresses included in a range.

When you specify an IPv4 address such as `172.16.10.1/24`, you are actually handling two different types of information:

- The IP address itself, `172.16.10.1`
- The subnet mask which indicates the network

The network number is the IP which has all zeroes in the host portion. In our example, because the prefix is 24, we identify our network number to have the last 8 (32-24) bits all zeroes. Thus, IP address `172.16.10.1/24` belongs to network `172.16.10.0/24`.

This is very important because, for instance, IP `172.16.10.1/16` is very different to the previous one, belonging to the very different network `172.16.0.0/16`.

#### Networks

With Subnet it's very easy to calculate the network for an IP address

```crystal
ip = Subnet.pars  "172.16.10.1/24"

net = ip.network
# => #<Subnet::IPv4:0xb7a5ab24 @octets=[172, 16, 10, 0], 
                               @prefix=24,
                               @address="172.16.10.0">
net.to_string
# => "172.16.10.0/24"
```
The method `IPv4#network` creates a new IPv4 object from the network number, calculated after the original object. I want to outline here that the network address is a perfectly legitimate IPv4 address, which just happen to have all zeroes in the host portion.

You can use method `IPv4#network?` to check whether an IP address is a network or not

```crystal
ip1 = Subnet::IPv4.new "172.16.10.1/24"
ip2 = Subnet::IPv4.new "172.16.10.4/30"

ip1.network?
# => false
ip2.network?
# => true
```

#### Broadcast

The broadcast address is the oposite of the network number: where the network number has all zeroes in the host portion, the broadcast address has all one's. For example, the ip `172.16.10.1/24` has the broadcast `172.16.10.255/24`, where the ip `172.16.10.1/16` has the broadcast `172.16.255.255/16`.

The method `IPv4#broadcast` has the same behavior as its `#network` counterpart: it creates a new IPv4 object to handle the broadcast address

```crystal
ip = Subnet::IPv4.new("172.16.10.1/24")

bcast = ip.broadcast
# => #<Subnet::IPv4:0xb7a406fc @octets=[172, 16, 10, 255],
                               @prefix=24, 
                               @address="172.16.10.255">
bcast.to_string
# => "172.16.10.255/24"
```

### Addresses, ranges, and iterators

Class `IPv4` includes the `Iterator` and `Enumberable` modules, as well as having the methods `succ` and `pred` which allow it to be used with `Range`. This makes creating sets of addresses very easy, and very powerful.

Let's start with `IPv4#each`, which iterates over all addresses in a range

```crystal
ip = Subnet::IPv4.new("172.16.10.1/24")

ip.each do |addr|
  puts addr
end
```

It is important to note that it doesn't matter if the original IP is a host IP or a network number (or a broadcast address): the `#each` method only considers the range that the original IP specifies.

If you only want to iterate over hosts IP, use the `IPv4#each_host` method

```crystal
ip = Subnet::IPv4.new("172.16.10.1/24")

ip.each_host do |host|
  puts host
end
```

Methods `IPv4#first` and `IPv4#last` return a new object containing respectively the first and the last host address in the range

```crystal
ip = Subnet:IPv4.new("172.16.10.100/24")

ip.first.to_string
# => "172.16.10.1/24"

ip.last.to_string
# => "172.16.10.254/24"
```

Checking if an address is loopback is easy with the `IPv4#loopback?` method

```crystal
ip = IPAddress "127.0.0.1"

ip.loopback?
# => true
```

Checking if an address is in the multicast range can be done using the `IPv4#multicast?` method

```crystal
ip = IPAddress "224.0.0.1/32"

ip.multicast?
# => true
```

The ability to generate a range also exists by using the `IPv4#to()` method. This allows you to create a subnet agnostic range based off a fixed amount.

```crystal
ip = IPAddress "172.16.10.100/24"
ip.to("172.16.10.110")
# => ["172.16.10.100", ..., "172.16.10.110"]
```

As mentioned previously, you can also create Crystal Ranges using the Range literal

```crystal
range = Subnet.parse("192.168.0.1")..Subnet.parse("192.168.0.255")
puts range.size
# => 255
```

## Contributing

1. Fork it (<https://github.com/watzon/subnet/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer
