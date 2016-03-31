$LOAD_PATH << File.dirname(__FILE__)+"/daemons/lib"
require 'pathname'
$LOAD_PATH << File.dirname(__FILE__)
require 'amazeeio_cachalot/dnsmasq'

require 'amazeeio_cachalot.rb'

require 'socket'

module DnsCli
  def self.start(op)

    dns = Dnsmasq.new(self.docker_ip, false)

    case op
    when "start"
      dns.up
    when "stop"
      dns.halt
    when "restart"
      dns.halt
      dns.up
    else
      $stderr.puts "unknown dns subcommand: #{op}"
    end
  end

  def self.docker_ip
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

    addr = TCPSocket.gethostbyname("docker.local")
    addr.last
  ensure
    Socket.do_not_reverse_lookup = orig
  end

end
