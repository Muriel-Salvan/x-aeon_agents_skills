module XAeonAgentsSkills

  class SkillsDsl

    # Create a new DSL instance
    #
    # Result:: SkillsDsl instance
    def initialize
      @skills = []
      @current_repo = nil
    end

    # @return [Array<String>] The list of parsed skills
    attr_reader :skills

    # Add a skill reference to the list
    #
    # Parameter::
    # * skill_ref [String] The skill reference to add
    def skill(skill_ref)
      if @current_repo
        @skills << "#{@current_repo}/#{skill_ref}"
      else
        @skills << skill_ref
      end
    end

    # Set the repository context for nested skill calls
    #
    # Parameter::
    # * repo_name [String] The repository name
    # * block [Proc] The block to execute in the repository context
    def from_skills(repo_name, &block)
      previous_repo = @current_repo
      @current_repo = repo_name
      instance_eval(&block) if block
      @current_repo = previous_repo
    end

  end

end
