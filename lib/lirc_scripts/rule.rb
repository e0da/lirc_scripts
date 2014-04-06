  class Rule
    attr_reader :name, :command

    def initialize(line)
      @name, @command = line.split(' ', 2)
    end
  end
