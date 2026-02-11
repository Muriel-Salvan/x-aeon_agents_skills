module XAeonAgentsSkills

  # Return the current AI agent name
  #
  # Result::
  # * String: The current AI agent name
  def self.agent_name
    # TODO: Make this adaptable to different agents using plugins
    require 'sqlite3'
    require 'json'

    # Find VSCode globalStorage database
    state_db = "#{ENV['VSCODE_PORTABLE'] ? "#{ENV['VSCODE_PORTABLE']}/user-data" : "#{ENV['APPDATA']}/Code"}/User/globalStorage/state.vscdb"
    raise "Cannot find #{state_db}" unless File.exist?(state_db)

    # Open SQLite database and query for our extension's key
    db = SQLite3::Database.new(state_db)
    db.results_as_hash = true
    row = db.get_first_row("SELECT value FROM ItemTable WHERE key = ?", "saoudrizwan.claude-dev")
    db.close
    raise 'Key \'saoudrizwan.claude-dev\' not found in database.' unless row

    "Cline (#{JSON.parse(row['value'])['actModeOpenRouterModelId']})"
  end

  # Return the agent signature that is added in any description authored by the AI agent
  #
  # Result::
  # * String: AI agent signature
  def self.agent_signature
    "\n\nCo-authored by: #{agent_name}"
  end

end
