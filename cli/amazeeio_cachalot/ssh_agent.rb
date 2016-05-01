require_relative 'docker_service'

class SshAgent < DockerService
  def image_name
    'amazeeio/ssh-agent'
  end

  def name
    'ssh-agent'
  end

  def container_name
    'amazeeio-ssh-agent'
  end

  def run_cmd
    "docker run -d " \
    "--restart=always " \
    "--name=#{Shellwords.escape(self.container_name)} " \
    "#{Shellwords.escape(self.image_name)}"
  end
end
