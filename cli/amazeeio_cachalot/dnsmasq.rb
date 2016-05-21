require_relative 'docker_service'

class Dnsmasq < DockerService

  def image_name
    'andyshinn/dnsmasq:2.75'
  end

  def name
    'dnsmasq'
  end

  def container_name
    'amazeeio-dnsmasq'
  end

  def domain
    'docker.amazee.io'
  end

  def run_cmd
    "docker run --restart=always -d -p 53:53/tcp -p 53:53/udp --name=#{Shellwords.escape(self.container_name)} " \
    "--cap-add=NET_ADMIN #{Shellwords.escape(self.image_name)} -A /#{Shellwords.escape(self.domain)}/#{Shellwords.escape(@machine.vm_ip)}"
  end
end
