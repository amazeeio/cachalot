require 'tempfile'

class Sudoers
  SUDOERS_DIR = Pathname.new("/etc/sudoers.d")


  def initialize()
    @sudoers_file = SUDOERS_DIR.join('amazeeio')
  end


  def install
    unless sudoers_configured?
      configure_sudoers!
    end
  end

  def name
    "SUDOERS"
  end

  def clean?
    puts "Removing sudoers file, this may require sudo"
    self.system!("removing sudoers file", "sudo", "rm", "-f", @sudoers_file)
    system!("restarting mDNSResponder", "sudo", "killall", "mDNSResponder")
  end

  def configure_sudoers!
    puts "setting up sudo privileges, this will require sudo"
    unless SUDOERS_DIR.directory?
      system!("creating #{SUDOERS_DIR}", "sudo", "mkdir", "-p", SUDOERS_DIR)
    end
    Tempfile.open('amazeeio_cachalot-sudoers') do |f|
      f.write(sudoers_contents)
      f.close
      system!("creating #{@sudoers_file}", "sudo", "cp", f.path, @sudoers_file)
      system!("creating #{@sudoers_file}", "sudo", "chmod", "444", @sudoers_file)
    end
  end

  def sudoers_configured?
    @sudoers_file.exist? && File.read(@sudoers_file) == sudoers_contents
  end

  def system!(step, *args)
    system(*args.map(&:to_s)) || raise("Error with #{name} during #{step}")
  end

  def sudoers_contents; <<-EOS.gsub(/^    /, '')
    # generated by amazeeio-cachalot
    Cmnd_Alias AMAZEEIO_NFS = /usr/local/opt/cachalot/bin/amazeeio-cachalot nfs *
    Cmnd_Alias AMAZEEIO_RESOLVER = /bin/rm -f /etc/resolver/docker.amazee.io
    Cmnd_Alias AMAZEEIO_MDNS = /usr/bin/killall mDNSResponder
    Cmnd_Alias AMAZEEIO_RESOLVER_UP = /bin/cp * /etc/resolver/docker.amazee.io
    Cmnd_Alias AMAZEEIO_RESOLVER_CHMOD = /bin/chmod 644 /etc/resolver/docker.amazee.io
    %admin ALL=(root) NOPASSWD: AMAZEEIO_NFS, AMAZEEIO_RESOLVER, AMAZEEIO_MDNS, AMAZEEIO_RESOLVER_UP, AMAZEEIO_RESOLVER_CHMOD
    EOS
  end
end
