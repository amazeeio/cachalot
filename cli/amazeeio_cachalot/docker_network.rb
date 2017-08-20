require_relative 'docker_service'


class DockerNetwork < DockerService

  def network_name
    'amazeeio-network'
  end

  def haproxy_name
    'amazeeio-haproxy'
  end

  def create_cmd
    "docker network create --subnet=10.99.99.0/24 --gateway=10.99.99.1 #{self.network_name}"
  end

  def delete_cmd
    "docker network rm #{self.network_name}"
  end

  def connect_haproxy_cmd
    "docker network connect #{self.network_name} #{self.haproxy_name}"
  end

  def create
    unless self.exists?
      unless docker.system(self.create_cmd).success?
        raise RuntimeError.new(
          "Failed to create #{self.network_name}.  Command #{self.create_cmd} failed"
        )
      end
    end
    self.exists?
  end

  def delete
    if self.exists?
      if docker.system(self.delete_cmd)
        puts "#{self.network_name} network successfully deleted"
      else
        puts "#{self.network_name} network failed to delete"
      end
    end
    !self.exists?
  end

  def connect
    unless self.haproxy_connected?
      unless docker.system(self.connect_haproxy_cmd).success?
        raise RuntimeError.new(
          "Failed to connect #{self.haproxy_name} to #{self.network_name}.  Command #{self.connect_haproxy_cmd} failed"
        )
      end
    end
    self.haproxy_connected?
  end

  def haproxy_connected?(network_name = self.network_name, haproxy_name = self.haproxy_name)
    !!(self.inspect_containers(network_name) =~ /#{haproxy_name}/)
  end

  def exists?(network_name = self.network_name)
    !!(self.ls =~ /#{network_name}/)
  end

  def inspect_containers(network_name = self.network_name)
    cmd = "docker network inspect #{self.network_name} -f '{{.Containers}}'"
    ret = docker.system(cmd)
    if ret.success?
      return ret.stdout
    else
      raise RuntimeError.new("Failure running command '#{cmd}'")
    end
  end

  def ls
    cmd = "docker network ls"
    ret = docker.system(cmd)
    if ret.success?
      return ret.stdout
    else
      raise RuntimeError.new("Failure running command '#{cmd}'")
    end
  end

end
