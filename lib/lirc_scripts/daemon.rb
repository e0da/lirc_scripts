require 'lirc'
require 'lirc_scripts/rule'
require 'singleton'
require 'yaml'

module LIRCScripts
  class Daemon
    include Singleton

    def self.run
      instance.send :start_main_loop
    end

    def self.reload_rules
      instance.send :load_rules
    end

    private

    def initialize
      load_rules
    end

    def start_main_loop
      LIRC::Client.new.tap do |lirc|
        while event = lirc.next
          unless too_soon? event
            log "LIRC event: #{event.name}"
            handle event
          end
        end
      end
    end

    def log(*args)
      puts args
    end

    def too_soon?(event)
      event.repeat > 0
    end

    def handle(event)
      @rules.find_all do |rule|
        rule.keys.include? event.name
      end.each do |rule|
        fork do
          IO.popen rule.command do |io|
            log "Running `#{rule.command}` with pid #{io.pid}..."
            log io.gets
          end
        end
      end
    end

    def load_rules
      @rules = []
      YAML.load_file('config/rules.yml').each do |rule|
        @rules << Rule.new(rule)
      end
    end

    def comment?(line)
      line =~ /^#/
    end
  end
end
