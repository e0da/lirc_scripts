require 'lirc'
require 'lirc_scripts/rule'
require 'singleton'

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
      @rules[event.name].tap do |command|
        next if command.nil?
        fork do
          IO.popen command do |io|
            log "Running `#{command.chomp}` with pid #{io.pid}..."
            log io.gets
          end
        end
      end
    end

    def load_rules
      @rules = {}
      File.readlines('config/rules').each do |line|
        next if comment? line
        Rule.new(line).tap do |rule|
          @rules[rule.name] = rule.command
          log "Added rule: #{rule.name}: #{rule.command}"
        end
      end
    end

    def comment?(line)
      line =~ /^#/
    end
  end
end
