require 'shellwords'
require 'amazeeio_cachalot/shell'

class DockerService

  def initialize(machine)
    @machine = machine
  end

  def start
    unless self.running?
      success = if self.container_exists?
                  docker.system(self.start_cmd).success?
                else
                  docker.system(self.run_cmd).success?
                end
      unless success
        raise RuntimeError.new(
          "Failed to run #{self.container_name}.  Command #{self.run_cmd} failed"
        )
      end
    end
    self.running?
  end

  def pull
    puts "Pulling Docker Image #{Shellwords.escape(self.image_name)}".yellow
    success = docker.system("docker pull #{Shellwords.escape(self.image_name)}").success?
    unless success
      raise RuntimeError.new(
        "Failed to update #{self.container_name}.  Command #{self.pull_cmd} failed"
      )
    end
  end

  def running?
    !!(self.ps =~ /#{self.container_name}/)
  end

  def container_exists?
    !!(self.ps(true) =~ /#{self.container_name}/)
  end

  def ps(all = false)
    cmd = "docker ps#{all ? ' -a' : ''}"
    ret = docker.system(cmd)
    if ret.success?
      return ret.stdout
    else
      raise RuntimeError.new("Failure running command '#{cmd}'")
    end
  end


  def stop
    docker.system("docker stop -t 1 #{Shellwords.escape(self.container_name)}") if self.running?
    !self.running?
  end

  def delete
    if self.container_exists?
      self.stop if self.running?
      docker.system("docker rm #{Shellwords.escape(self.container_name)}")
    end
    !self.container_exists?
  end

  def start_cmd
    "docker start #{Shellwords.escape(self.container_name)}"
  end

  def docker
    @docker ||= Docker.new(@machine)
  end

  def halt
    if stop
      puts "#{self.name} container stopped"
      if delete
        puts "#{self.name} container successfully deleted"
      else
        puts "#{self.name} container failed to delete"
      end
    else
      puts "#{self.name} container failed to stop"
    end
  end
end
