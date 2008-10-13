require 'daemon_controller'

# This class uses daemon_controller to start local sphinx daemon if its not running.
# Obviously it is only useful for local daemons. for remote daemons will have to override connect and change start command
module Ultrasphinx
  class DaemonControllerConnector

    def initialize
      @port = Ultrasphinx::CLIENT_SETTINGS['server_port']
      @controller = DaemonController.new(
      :identifier => 'Sphinx search server',
      :start_command => start_command,
      :ping_command => ping_command,
      :before_start => method(:before_start),
      :pid_file => Ultrasphinx::DAEMON_SETTINGS["pid_file"],
      :log_file => Ultrasphinx::DAEMON_SETTINGS["log"])
    end

    def connect
      @controller.connect { TCPSocket.new('localhost', @port) }
    end

    private

    def start_command
      "searchd --config '#{Ultrasphinx::CONF_PATH}'"
    end

    def ping_command
      lambda {TCPSocket.new('localhost', @port)}
    end

    def before_start
      Ultrasphinx.say "Configuring sphinx..."
      create_directories
      Ultrasphinx::Configure.run
      if !index_exists?
        Ultrasphinx.say "building main index..."
        ultrasphinx_index(Ultrasphinx::MAIN_INDEX)
      end
    end

    # following section is taken from ultrasphinx rake tasks. needs refactoring and DRYing
    include FileUtils
    def index_exists?
      # HACK: what is the proper way to check for index existance?
      File.exists? File.join(Ultrasphinx::INDEX_SETTINGS['path'], "sphinx_index_main.spa")
    end

    def create_directories
      dir = Ultrasphinx::INDEX_SETTINGS['path']
      mkdir_p(dir) unless File.directory?(dir)
    end

    def ultrasphinx_index(index)
      cmd = "indexer --config '#{Ultrasphinx::CONF_PATH}' #{index}"

      Ultrasphinx.say "$ #{cmd}"
      system cmd
    end

  end
end
