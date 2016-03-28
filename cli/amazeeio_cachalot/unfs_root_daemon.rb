require 'amazeeio_cachalot/daemon'

class UnfsRootDaemon
  include AmazeeIOCachalot::Daemon
  attr_reader :dir, :command

  def initialize(var_dir, command_args)
    @dir = var_dir
    @command = command_args
  end

  def name
    "NFS"
  end
end
