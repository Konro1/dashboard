require 'yaml'
require 'json'

# Class that gathers all the settings and handles a simple logic for some specific config variables
class Configurator

  def initialize
    @CONFIGS = {}

    # list of config files to be merged
    @CONFIG_FILES = [
      "provisioning/default.settings.yml",
      "settings.yml"
    ]

    self.load_configs
  end

  # loads config files and merges them
  def load_configs
    @CONFIG_FILES.each do |file|
      unless File.exist?(file)
        next
      end

      loaded = YAML::load_file(file)
      unless loaded === false
        @CONFIGS = self.merge(@CONFIGS, loaded)
      end
    end

    # run the logic for specific config variables
    self.do_logic

    @CONFIGS
  end

  # logic for specific config variables
  # finds all methods which names starts from "_get_" and run them
  def do_logic
    self.methods.each do |method|
      unless method.to_s.start_with? '_get_'
        next
      end

      self.send(method)
    end
  end

  # returns config variable by it's path (keys names separated by dot)
  def get(path)
    value = @CONFIGS
    path.split('.').each do |p|
      if p.to_i.to_s == p
        value = value[p.to_i]
      else
        value = value[p.to_s]
      end
      break unless value
    end
    value
  end

  # same as `get`, but sets the value to a config variable
  def set(path, value)
    *key, last = path.split(".")
    tmp_hash = {}
    path.split(".").reduce(tmp_hash) { |h,m| h[m] = {} }
    key.inject(tmp_hash, :fetch)[last] = value
    @CONFIGS = self.merge(@CONFIGS, tmp_hash)
  end

  # helper method for recursive merging
  def merge(h1, h2)
    h1.merge(h2){|key, oldval, newval|
      if oldval.is_a?(Hash) && newval.is_a?(Hash)
        self.merge(oldval, newval)
      else
        newval
      end
    }
  end

  # returns all settings
  def get_all_settings(as_json = false)
    if as_json == true
      @CONFIGS.to_json
    else
      @CONFIGS
    end
  end

  ## methods that define a bit of logic for the settings

  # if host name is emty then use project name as host name
  def _get_network_host_name
    if self.get('network.host.name').nil?
      self.set('network.host.name', self.get('project.name'))
    end
  end

  # if there is no host set then use host prefix and host name
  def _get_webserver_host
    if self.get('webserver.host').nil?
      self.set('webserver.host', self.get('network.host.prefix') + '.' + self.get('network.host.name'))
    end
  end

  # if there is no IP set then use random IP
  def _get_network_ip
    if self.get('network.ip').nil?
      # computing of a simple checksum
      sum = 250 # just a random number
      self.get('project.name').split("").each do | char |
        sum += char[0].ord
      end

      # computing 2 parts of IP; 0 > part < 256
      part_1 = [[sum & 0xff,  1].max, 255].min
      part_2 = [[(sum * 2) & 0xff, 1].max, 255].min

      # generating IP
      self.set('network.ip', "192.168." + part_1.to_s + "." + part_2.to_s)
    end
  end

  # if thre is no virtual machine name then generate a pseudo-unique name from box name and project name
  # unique virtual machine name is needed to prevent installing different projects on the same VM
  def _get_vm_name
    if self.get('vm.name').nil?
      self.set('vm.name', self.get('vm.box.name').gsub('/', '-') + '-' + self.get('project.name'))
    end
  end

  def _get_php_extensions_list
    list = [
      'php-pear',
    ]

    self.get('php.extensions').each { | name, value |
      next if value == false
      list << 'php5-' + name
    }

    self.set('php.extensions', list)
  end

  def _get_pecl_extensions_list
    list = []

    self.get('php.pecl_extensions').each { | name, value |
      next if value == false
      list << name
    }

    self.set('php.pecl_extensions', list)
  end

end
