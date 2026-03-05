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

  end

end
