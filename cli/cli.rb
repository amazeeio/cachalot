$LOAD_PATH << File.dirname(__FILE__)+"/thor/lib"
require 'thor'
$LOAD_PATH << File.dirname(__FILE__)+"/daemons/lib"
require 'daemons'
$LOAD_PATH << File.dirname(__FILE__)+"/colorize/lib"
require 'colorize'

$LOAD_PATH << File.dirname(__FILE__)

require 'amazeeio_cachalot.rb'
require 'amazeeio_cachalot/check_env'
require 'amazeeio_cachalot/docker'
require 'amazeeio_cachalot/dnsmasq'
require 'amazeeio_cachalot/resolver'
require 'amazeeio_cachalot/sudoers'
require 'amazeeio_cachalot/fsevents_to_vm'
require 'amazeeio_cachalot/unfs'
require 'amazeeio_cachalot/machine'
require 'amazeeio_cachalot/machine/create_options'
require 'amazeeio_cachalot/system'
require 'amazeeio_cachalot/version'
require 'amazeeio_cachalot/docker_service'
require 'amazeeio_cachalot/docker_network'
require 'amazeeio_cachalot/haproxy'
require 'amazeeio_cachalot/mailhog'
require 'amazeeio_cachalot/ssh_agent'
require 'amazeeio_cachalot/ssh_agent_add_key'

$0 = 'amazeeio-cachalot' # fix our binary name, since we launch via the _amazeeio_cachalot_command wrapper

class AmazeeIOCachalotCLI < Thor
  option :memory,
    type: :numeric,
    aliases: :m,
    desc: "virtual machine memory size (in MB) (default #{MEM_DEFAULT})"
  option :cpus,
    type: :numeric,
    aliases: :c,
    desc: "number of CPUs to allocate to the virtual machine (default #{CPU_DEFAULT})"
  option :disk,
    type: :numeric,
    aliases: :d,
    desc: "size of the virtual disk to create, in MB (default #{DISK_DEFAULT})"
  option :provider,
    aliases: :p,
    desc: "which docker-machine provider to use, 'virtualbox', 'vmware', 'xhyve', or 'parallels'"
  option :boot2docker_url,
    type: :string,
    aliases: :u,
    desc: 'URL of the boot2docker image'
  option :hostonly_cidr,
    type: :string,
    aliases: :h,
    desc: 'Specify the Host Only CIDR eg. "192.168.99.1/24"'
  desc "create", "create the docker-machine VM"
  def create
    puts "    _".white
    puts "  /   \\".white
    puts " ( I/O )   cachalot.amazee.io".white
    puts "  \\ _ /\n".white

    if machine.created?
      $stderr.puts "The VM '#{machine.name}' already exists in docker-machine.".yellow
      $stderr.puts "Run `amazeeio-cachalot up` to bring up the VM, or `amazeeio-cachalot destroy` to delete it.".yellow
      exit(1)
    end

    create_options = ({}).merge(options)
    create_options['provider'] = machine.translate_provider(create_options['provider'])

    if create_options['provider'].nil?
      $stderr.puts("Invalid value for required option --provider. Valid values are: 'virtualbox', 'vmware', 'xhyve', or 'parallels'")
      exit(1)
    end

    puts "Creating the #{machine.name} VM, this takes a while and during this the machine will shortly be stopped, no worries...".yellow
    machine.create(create_options)
    start_services
    puts "\nYou now are running the amazee.io Docker Development Environment".light_cyan
    puts "Don't know what to do now? Visit docker.docs.amazee.io to learn more".light_cyan
  end

  desc "up", "start the Docker VM and services"
  def up
    puts "    _".white
    puts "  /   \\".white
    puts " ( I/O )   cachalot.amazee.io is starting...".white
    puts "  \\ _ /\n".white

    puts "Starting the virtual machine...".yellow
    vm_must_exist!
    if machine.running?
      puts "The VM '#{machine.name}' is already running.".green
    end

    start_services
  end

  map "start" => :up

  desc "docker_start", "starts the docker containers and network"
  def docker_start
    # this is hokey, but it can take a few seconds for docker daemon to be available
    # TODO: poll in a loop until the docker daemon responds
    puts "\nStarting Docker Containers and network...".yellow
    sleep 5

    if dockernetwork.create
      puts "Successfully created amazeeio network".green
    else
      puts "Error creating amazeeio network".red
    end

    if haproxy.start
      puts "Successfully started Haproxy".green
    else
      puts "Error starting Haproxy".red
    end

    if dockernetwork.connect
      puts "Successfully connected haproxy to amazeeio network".green
    else
      puts "Error connecting haproxy to amazeeio network".red
    end

    if sshagent.start
      puts "Successfully started ssh-agent".green
    else
      puts "Error starting ssh-agent".red
    end

    if dnsmasq.start
      puts "Successfully started dnsmasq".green
    else
      puts "Error starting dnsmasq".red
    end

    if mailhog.start
      puts "Successfully started Mailhog".green
    else
      puts "Error starting Mailhog".red
    end

    if sshagentaddkey.add_ssh_key
      puts "Successfully injected ssh key".green
    else
      puts "Error injected ssh key".red
    end
  end

  desc "ssh [args...]", "ssh to the VM"
  def ssh(*args)
    vm_must_exist!
    machine.ssh_exec(*args)
  end

  desc 'docker_update', 'Pulls Docker Images and recreates the Containers'
  def docker_update
    haproxy.pull
    sshagent.pull
    dnsmasq.pull
    mailhog.pull
    puts "Done. Recreating containers...".yellow
    docker_halt
    docker_start
  end

  desc 'docker_restart', 'Restarts all Docker Containers'
  def docker_restart
    docker_halt
    docker_start
  end

  desc 'docker_status', 'Get Status of Docker containers'
  def docker_status
    puts "\n[docker containers & network]".yellow
    if haproxy.running?
      puts "Haproxy: Running as docker container #{haproxy.container_name}".light_green
    else
      puts "Haproxy is not running".red
    end

    if dockernetwork.exists?
      puts "Network: Exists as name #{dockernetwork.network_name}".light_green
    else
      puts "Network does not exist".red
    end

    if dockernetwork.haproxy_connected?
      puts "Network: Haproxy #{dockernetwork.haproxy_name} connected to #{dockernetwork.network_name}".light_green
    else
      puts "Haproxy is not connected to #{dockernetwork.network_name}".red
    end

    if dnsmasq.running?
      puts "Dnsmasq: Running as docker container #{dnsmasq.container_name}".light_green
    else
      puts "Dnsmasq is not running".red
    end

    if mailhog.running?
      puts "Mailhog: Running as docker container #{mailhog.container_name}".light_green
    else
      puts "Mailhog is not running".red
    end

    if sshagent.running?
      puts "ssh-agent: Running as docker container #{sshagent.container_name}, loaded keys:".light_green
      sshagentaddkey.show_ssh_keys
    else
      puts "ssh-agent is not running".red
    end
    puts
  end

  desc "status", "get VM and services status"
  def status
    puts "[virtual machine]".yellow
    if machine.running?
      puts "#{machine.status}".light_green
    else
      puts "#{machine.status}".red
    end
    puts "\n[services]".yellow
    if unfs.running?
      puts "NFS: #{unfs.status}".light_green
    else
      puts "NFS: #{unfs.status}".red
    end
    if fsevents.running?
      puts "FsEvents: #{fsevents.status}".light_green
    else
      puts "FsEvents: #{fsevents.status}".red
    end

    return unless machine.status == 'running'
    [unfs, fsevents].each do |daemon|
      if !daemon.running?
        puts "\n\e[33m#{daemon.name} failed to run\e[0m"
        puts "details available in log file: #{daemon.logfile}"
      end
    end

    puts "\n[resolver]".yellow
    if resolver.resolver_configured?
      puts "Resolver: correctly configured".light_green
    else
      puts "Resolver: not configured".red
    end

    puts "\n[sudoers]".yellow
    if sudoers.sudoers_configured?
      puts "sudoers: correctly configured".light_green
    else
      puts "sudoers: not configured".red
    end

    docker_status

    CheckEnv.new(machine).run

    puts "\namazee.io wishes happy Drupaling!".light_cyan
  end

  desc "myip", "get the hosts IP address"
  def myip
    vm_must_exist!
    if machine.running?
      puts machine.host_ip
    else
      $stderr.puts "The VM is not running, `amazeeio_cachalot up` to start"
      exit 1
    end
  end

  desc "ip", "get the VM's IP address"
  def ip
    vm_must_exist!
    if machine.running?
      puts machine.vm_ip
    else
      $stderr.puts "The VM is not running, `amazeeio_cachalot up` to start"
      exit 1
    end
  end

  desc "halt", "stop the VM and services"
  def halt
    puts "    _".white
    puts "  /   \\".white
    puts " ( I/O )   cachalot.amazee.io is stopping...".white
    puts "  \\ _ /\n".white
    vm_must_exist!
    fsevents.halt
    unfs.halt
    resolver.clean?
    docker_stop
    puts "Stopping the #{machine.name} VM..."
    machine.halt
  end

  desc "docker_stop", "stop the Docker Containers"
  def docker_stop
    haproxy.stop
    dnsmasq.stop
    mailhog.stop
    sshagent.stop
  end

  desc "docker_halt", "stop and remove the Docker Containers"
  def docker_halt
    haproxy.halt
    dnsmasq.halt
    mailhog.halt
    sshagent.halt
  end

  desc "dockernetwork_remove", "remove the docker network"
  def dockernetwork_remove
    dockernetwork.delete
  end

  map "down" => :halt
  map "stop" => :halt

  desc "restart", "restart the VM and services"
  def restart
    halt
    up
  end

  option :force,
    type: :boolean,
    aliases: :f,
    desc: "destroy without confirmation"
  desc "destroy", "stop and delete all traces of the VM"
  def destroy
    vm_must_exist!
    fsevents.halt
    unfs.halt
    resolver.clean?
    machine.destroy(force: options[:force])
  end

  desc "upgrade", "upgrade the boot2docker VM to the newest available"
  def upgrade
    vm_must_exist!
    machine.upgrade
    # restart to re-enable the http proxy, etc
    restart
  end

  desc "env", "returns env variables to set, should be run like $(amazeeio_cachalot env)"
  def env
    vm_must_exist!
    CheckEnv.new(machine).print
  end

  desc 'addkey [~/.ssh/id_rsa]', 'Add additional ssh-key'
  def addkey(key = "#{Dir.home}/.ssh/id_rsa")
    sshagentaddkey.add_ssh_key(key)
  end

  map "shellinit" => :env

  map "-v" => :version
  desc "version", "display amazeeio_cachalot version"
  def version
    puts "AmazeeIOCachalot #{CACHALOT_VERSION}"
  end

  desc 'sudoers_configure', 'Set up the sudoers file so you are not prompted for credentials all the time'
  def sudoers_configure!
    sudoers.install()
  end

  private

  def vm_must_exist!
    if !machine.created?
      $stderr.puts "The VM '#{machine.name}' does not exist in docker-machine."
      $stderr.puts "Run `amazeeio_cachalot create` to create the VM, `amazeeio_cachalot help create` to see available options."
      exit(1)
    end
  end


  def machine
    @machine ||= Machine.new()
  end

  def unfs
    @unfs ||= Unfs.new(machine)
  end

  def resolver
    @resolver ||= Resolver.new(machine.vm_ip)
  end

  def sudoers
    @sudoers ||= Sudoers.new()
  end

  def haproxy
    @haproxy ||= Haproxy.new(machine)
  end

  def dockernetwork
    @dockernetwork ||= DockerNetwork.new(machine)
  end

  def sshagent
    @sshagent ||= SshAgent.new(machine)
  end

  def sshagentaddkey
    @sshagentaddkey ||= SshAgentAddKey.new(machine)
  end

  def dnsmasq
    @dnsmasq ||= Dnsmasq.new(machine)
  end

  def mailhog
    @mailhog ||= Mailhog.new(machine)
  end

  def fsevents
    FseventsToVm.new(machine)
  end

  def start_services
    machine.up
    puts "\nStarting services...".yellow
    sudoers.install
    unfs.up
    if unfs.wait_for_unfs
      machine.mount(unfs)
    else
      puts "NFS mounting failed"
    end

    fsevents.up

    resolver.up
    # this is hokey, but it can take a few seconds for docker daemon to be available
    # TODO: poll in a loop until the docker daemon responds
    docker_start

    puts "\nAll started, here the current status:".light_blue
    status
  end
end
