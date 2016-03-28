require 'stringio'

require 'amazeeio_cachalot/machine'

class HttpProxy
  CONTAINER_NAME = "amazeeio_haproxy"
  IMAGE_NAME = "amazeeio/haproxy"

  attr_reader :machine

  def initialize(machine, amazeeio_cachalot_domain)
    @machine = machine
    @amazeeio_cachalot_domain = amazeeio_cachalot_domain
  end

  def up
    puts "Starting the HTTP & HTTPS proxy"
    System.capture_output do
      docker.system("rm", "-fv", CONTAINER_NAME)
    end
    docker.system("run", "-d",
      "-p", "80:80",
      "-p", "443:443",
      "-v", "/var/run/docker.sock:/tmp/docker.sock",
      "--name", CONTAINER_NAME, IMAGE_NAME)
  end

  def status
    return "stopped" if !machine.running?

    output, _ = System.capture_output do
      docker.system("inspect", "-f", "{{ .State.Running }}", CONTAINER_NAME)
    end

    if output.strip == "true"
      "running"
    else
      "stopped"
    end
  end

  private

  def docker
    @docker ||= Docker.new(machine)
  end
end
