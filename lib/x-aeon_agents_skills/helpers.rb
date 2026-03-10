require 'open3'

module XAeonAgentsSkills

  module Helpers

    # Deep merge two hashes recursively, preserving nested structures
    #
    # Parameters::
    # * *target* (Hash): Hash in which we merge the source
    # * *source* (Hash): Hash that we meerge in the target (overriding its values)
    # Result::
    # * Hash: Merged hash
    def self.deep_merge(target, source)
      target.merge(source) do |key, oldval, newval|
        if oldval.is_a?(Hash) && newval.is_a?(Hash)
          deep_merge(oldval, newval)
        else
          newval
        end
      end
    end

    # Execute a command while capturing its output in real time
    #
    # Parameters::
    # * *cmd* (String): Command to be run
    # * *debug* (Boolean): Do we activate debug mode? [default: false]
    # * *expected_exit_status* (Integer or nil): Expected exit status, or nil for no expectation [default: 0]
    # * *on_stdout* (Proc or nil): Code called for each line of stdout, or nil if no code to be called [default: nil]
    #   * Parameters::
    #     * *line* (String): Line of stdout
    # * *on_stderr* (Proc or nil): Code called for each line of stderr, or nil if no code to be called [default: nil]
    #   * Parameters::
    #     * *line* (String): Line of stderr
    # Result::
    # * Hash<Symbol,Object>: Command final output:
    #   * *stdout* (String): Full stdout
    #   * *stderr* (String): Full stderr
    #   * *exit_status* (Integer): Exit status
    def self.run_cmd(cmd, debug: false, expected_exit_status: 0, on_stdout: nil, on_stderr: nil)
      stdout_lines = []
      stderr_lines = []
      exit_status = nil
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        stdin.close
        [
          Thread.new do
            stdout.each_line do |line|
              stdout_lines << line
              on_stdout.call(line) unless on_stdout.nil?
            end
          end,
          Thread.new do
            stderr.each_line do |line|
              stderr_lines << line
              on_stderr.call(line) unless on_stderr.nil?
            end
          end
        ].each(&:join)
        exit_status = wait_thr.value.exitstatus
        puts "[DEBUG] - CLI `#{cmd}` exited with status: #{exit_status}" if debug
        raise "CLI `#{cmd}` exited with status #{exit_status} (expected #{expected_exit_status})" if !expected_exit_status.nil? && exit_status != expected_exit_status
      end
      {
        stdout: stdout_lines.join("\n"),
        stderr: stderr_lines.join("\n"),
        exit_status:
      }
    end

  end

end
