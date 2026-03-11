module XAeonAgentsSkills

  module Logger

    class << self
      # Global debug switch.
      attr_accessor :debug
    end

    # Log a message if debug was activated
    #
    # Parameters::
    # * *msg* (String or nil): Message to be displayed, or nil if the message is given lazily through a code block [default = nil]
    # * Proc: Code returning a String for lazy evaluation
    #   * Result::
    #     * String: Debug message
    def log_debug(msg = nil)
      if Logger.debug
        msg = yield if block_given?
        puts "[DEBUG] - #{msg}"
      end
    end

  end

end
