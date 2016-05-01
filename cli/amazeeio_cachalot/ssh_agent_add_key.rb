class SshAgentAddKey

  def initialize(machine)
    @machine = machine
  end

  def image_name
    'amazeeio/ssh-agent'
  end

  def container_name
    'amazeeio-ssh-agent-add-key'
  end

  def add_ssh_key(key = "#{Dir.home}/.ssh/id_rsa")
    if File.file?(key)
      docker.system_interactive("docker run --rm -it " \
      "--volume=#{key}:/#{key} " \
      "--volumes-from=amazeeio-ssh-agent " \
      "--name=#{Shellwords.escape(container_name)} " \
      "#{Shellwords.escape(image_name)} " \
      "ssh-add #{key}")
    else
      puts "ssh key: #{key}, does not exist, ignoring...".yellow
      return false
    end
  end

  def show_ssh_keys
    docker.system_interactive("docker run --rm -it " \
    "--volumes-from=amazeeio-ssh-agent " \
    "--name=#{Shellwords.escape(self.container_name)} " \
    "#{Shellwords.escape(self.image_name)} " \
    "ssh-add -l")
  end

  def docker
    @docker ||= Docker.new(@machine)
  end

end
