require 'stringio'

require 'amazeeio_cachalot/machine'

class SshAgent
  CONTAINER_NAME = "amazeeio_ssh-agent"
  IMAGE_NAME = "schnitzel/amazeeio_ssh-agent"

  attr_reader :machine

  def initialize(machine, unfs)
    @machine = machine
    @unfs = unfs
  end

  def up
    puts "Starting the SSH Agent"
    System.capture_output do
      docker.system("rm", "-fv", CONTAINER_NAME)
    end
    docker.system("run", "-d",
      "--name", CONTAINER_NAME, IMAGE_NAME)
    docker.system("run", "--rm",
      "--volumes-from=#{CONTAINER_NAME}",
      "-v", "#{@unfs.host_mount_dir}/.ssh:/ssh",
      "-it",
      IMAGE_NAME,
      "ssh-add", "/ssh/id_rsa")
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
