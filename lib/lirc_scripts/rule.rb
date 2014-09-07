module LIRCScripts
  class Rule
    attr_reader :command, :keys

    def initialize(rule)
      @command, @keys = rule['command'], rule['keys']
    end
  end
end
