class Installator

  def initialize
    @PACKAGES = []
    @PLUGINS = []

    self.determine_os
    if @OS == 'linux'
      self.determine_package_manager
    end
  end

  def add_packages(package)
    if !package.is_a? Array
      package = [package]
    end

    @PACKAGES.concat package
  end

  def install_packages
    @PACKAGES.each do |package|
      self.install_package package
    end
  end

  def install_package(package)
    if @OS == 'windows'
      return true
    end

    # Check if Ansible provisioner installed
    if `#{package["commands"]["check_prensence"]}`.empty?
      puts package["messages"]["package_not_installed"]

      if @OS != 'linux'
        # we're on macos
        puts package["messages"]["installation_instructions"]
        return false
      else
        if !package["commands"]["installation"].has_key?(@PACKAGE_MANAGER)
          puts package["messages"]["installation_instructions"]
          return
        end
        package["commands"]["installation"][@PACKAGE_MANAGER].each do |command|
          `#{command}`
        end
      end
    end

    return true
  end

  def add_plugins(plugin)
    if !plugin.is_a? Array
      plugin = [plugin]
    end

    @PLUGINS.concat plugin
  end

  def install_plugins
    @PLUGINS.each do |plugin|
      self.install_plugin(plugin)
    end
  end

  def install_plugin(plugin)
    if !plugin["platforms"].is_a?(Array)
      plugin["platforms"] = [plugin["platforms"]]
    end

    if (!plugin["platforms"].include?("all") && !plugin["platforms"].include?(@OS)) || Vagrant.has_plugin?(plugin["name"])
      return false
    end
    puts `vagrant plugin install #{plugin["name"]}`
  end

  def determine_os
    if RbConfig::CONFIG["host_os"] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      @OS = 'windows'
    elsif RbConfig::CONFIG["host_os"] =~ /darwin|mac os/
      @OS = 'macos'
    else
      @OS = 'linux'
    end
  end

  def determine_package_manager
    # we're on linux
    # trying to detect package manager
    @PACKAGE_MANAGER = false
    %w[yum apt-get].each do |manager|
      unless `which #{manager}`.empty?
        @PACKAGE_MANAGER = manager
        return @PACKAGE_MANAGER
      end
    end
  end

end
