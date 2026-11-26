# frozen_string_literal: true

require "json"
require "open3"
require "time"

module Sessions
  CLAUDE_DIR = File.join(Dir.home, ".claude")
  SESSION2MD = File.expand_path("../bin/session2md", __dir__)
  SHELLS = %w[bash zsh fish sh dash ksh].freeze
  ASKERS = %w[human peer].freeze
  PANE_FORMAT = "\#{session_name}\t\#{window_name}\t\#{window_id}\t\#{pane_id}\t\#{pane_current_command}"
  ANSI = /\e\[[\d;]*m|\e\]8;[^\e]*\e\\/
  DIM = "\e[2m"
  NBSP = " "
  PROMPT = "❯"
  RULE = /\A─+(?: .+ ─+)?\z/
  COMMAND_NAME = %r{<command-name>([^<]+)</command-name>}
  COMMAND_ARGS = %r{<command-args>([^<]*)</command-args>}
  PREVIEW_CHARS = 100
  ACTIVITY_LINES = 6
  POLL_SECONDS = 0.2
  TYPING_SECONDS = 3
  STOP_SECONDS = 5
  EXIT_SECONDS = 15
  STARTUP_SECONDS = 30

  module_function

  def fail!(message)
    abort "#{File.basename($PROGRAM_NAME)}: #{message}"
  end

  def usage!(usage, valid)
    if %w[-h --help].include?(ARGV.first)
      puts usage
      exit
    end
    abort usage unless valid
  end

  def tmux(*args, **options)
    out, err, status = Open3.capture3("tmux", *args, **options)
    fail!("tmux #{args.first}: #{err.strip}") unless status.success?
    out
  end

  def panes
    out, _err, status = Open3.capture3("tmux", "list-panes", "-a", "-F", PANE_FORMAT)
    return [] unless status.success?

    out.lines.map do |line|
      project, window, window_id, id, command = line.chomp.split("\t")
      Pane.new(target: Target.new(project, window), window_id:, id:, command:)
    end
  end

  def wait_until(seconds)
    deadline = Time.now + seconds
    until (result = yield)
      return if Time.now > deadline

      sleep POLL_SECONDS
    end
    result
  end

  def duration(seconds)
    minutes, seconds = seconds.to_i.divmod(60)
    hours, minutes = minutes.divmod(60)
    days, hours = hours.divmod(24)
    return "#{days}d #{hours}h" if days.positive?
    return "#{hours}h #{minutes}m" if hours.positive?
    return "#{minutes}m" if minutes.positive?

    "#{seconds}s"
  end

  def preview(text)
    line = text.to_s.gsub(/\s+/, " ").strip
    (line.length > PREVIEW_CHARS) ? "#{line[0, PREVIEW_CHARS]}…" : line
  end

  Target = Data.define(:project, :window) do
    def self.parse(text)
      project, window = text.to_s.split(":", 2)
      valid = [project, window].all? { |part| part.to_s.match?(/\A[\w.-]+\z/) }
      Sessions.fail!("name the session as <project>:<clone>, e.g. vibemetrics-api:two, not #{text.inspect}") unless valid
      new(project, window)
    end

    def name = "#{project}-#{window}"

    def to_s = "#{project}:#{window}"
  end

  Pane = Data.define(:target, :window_id, :id, :command) do
    def shell? = SHELLS.include?(command)

    def address = "#{target.project}:#{window_id}.#{id}"
  end

  Agent = Data.define(:pid, :session_id, :cwd, :status, :waiting_for, :version, :address) do
    def self.all
      Dir[File.join(CLAUDE_DIR, "sessions", "*.json")].filter_map do |file|
        next unless File.basename(file, ".json").match?(/\A\d+\z/)

        record = JSON.parse(File.read(file))
        next if record["tmux"].to_s.empty? || !running?(record)

        new(pid: record["pid"], session_id: record["sessionId"], cwd: record["cwd"], status: record["status"],
          waiting_for: record["waitingFor"], version: record["version"], address: record["tmux"])
      rescue JSON::ParserError, Errno::ENOENT
        nil
      end
    end

    def self.running?(record)
      pid = record["pid"]
      return Process.kill(0, pid).positive? unless Dir.exist?("/proc")

      started = File.read("/proc/#{pid}/stat")[/\)\s(.*)/m, 1].split[19]
      record["procStart"].nil? || record["procStart"] == started
    rescue Errno::ESRCH, Errno::ENOENT, TypeError
      false
    rescue Errno::EPERM
      true
    end

    def idle? = %w[idle shell].include?(status)

    def closable? = status == "idle"

    def asking? = status == "waiting"

    def state
      case status
      when "idle" then "idle"
      when "shell" then "idle, a background shell running"
      when "busy" then "working"
      when "waiting" then ["asking", waiting_for].compact.join(": ")
      when nil then "starting"
      else status
      end
    end
  end

  class Transcript
    attr_reader :path

    def initialize(agent)
      @path = File.join(CLAUDE_DIR, "projects", agent.cwd.gsub(/[^A-Za-z0-9]/, "-"), "#{agent.session_id}.jsonl")
    end

    def entries
      @entries ||= File.file?(path) ? File.foreach(path).with_index(1).filter_map { |line, number| parse(line, number) } : []
    end

    def last_at = at(entries.reverse_each.find { |entry| entry["timestamp"] })

    def ask = entries.reverse_each.find { |entry| ASKERS.include?(origin(entry)&.dig("kind")) }

    def asked_at = at(ask)

    def ask_text
      entry = ask or return
      origin(entry)["body"] || text(entry.dig("attachment", "prompt") || entry.dig("message", "content"))
    end

    def model = reply&.dig("message", "model")

    def context
      usage = reply&.dig("message", "usage") or return
      usage.values_at("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens").sum(&:to_i)
    end

    def latest_step
      block = Array(reply&.dig("message", "content")).last or return
      case block["type"]
      when "tool_use" then "#{block["name"]}: #{block["input"].to_h.values.first}"
      when "text" then block["text"]
      when "thinking" then "thinking"
      end
    end

    private

    def reply = entries.reverse_each.find { |entry| entry["type"] == "assistant" }

    def origin(entry) = entry["origin"] || entry.dig("attachment", "origin")

    def parse(line, number)
      JSON.parse(line).tap { |entry| entry["line"] = number }
    rescue JSON::ParserError
      nil
    end

    def at(entry) = entry && Time.iso8601(entry["timestamp"] || entry.dig("attachment", "timestamp"))

    def text(content)
      return Array(content).filter_map { |block| block["text"] }.join(" ") unless content.is_a?(String)

      name = content[COMMAND_NAME, 1] or return content
      [name, content[COMMAND_ARGS, 1]].compact.map(&:strip).reject(&:empty?).join(" ")
    end
  end

  class Screen
    def initialize(raw)
      @raw = raw.lines.map(&:chomp)
      @plain = @raw.map { |line| line.gsub(ANSI, "").tr(NBSP, " ").rstrip }
      @top = @plain.each_index.reverse_each.find { |row| @plain[row].match?(RULE) && @plain[row + 1].to_s.start_with?(PROMPT) }
      @bottom = @top && ((@top + 2)...@plain.size).find { |row| @plain[row].match?(RULE) }
    end

    def recognised? = !@bottom.nil?

    def input = @plain[(@top + 1)...@bottom].join("\n").delete_prefix(PROMPT).strip

    def input_state
      return :empty if input.empty?

      leading = @raw[@top + 1].split(PROMPT, 2).last.delete_prefix(NBSP).delete_prefix(" ")[/\A(?:\e\[[\d;]*m)*/]
      leading.include?(DIM) ? :suggestion : :typed
    end

    def typed? = recognised? && input_state == :typed

    def activity = @plain[0...@top].reject(&:empty?).last(ACTIVITY_LINES)

    def status = @plain[(@bottom + 1)..].reject(&:empty?)

    def text = @plain.reject(&:empty?)
  end

  class Window
    attr_reader :target

    def initialize(target)
      @target = target
    end

    def panes
      found = Sessions.panes.select { |pane| pane.target == target }
      if found.map(&:window_id).uniq.size > 1
        Sessions.fail!("#{target}: #{found.map(&:window_id).uniq.size} tmux windows share that name, so nothing was done. Rename all but one with tmux rename-window.")
      end
      found
    end

    def agent
      addresses = panes.map(&:address)
      Agent.all.find { |agent| addresses.include?(agent.address) }
    end

    def pane
      found = panes
      running = agent
      found.find { |pane| pane.address == running&.address } || found.first
    end

    def pane! = pane || Sessions.fail!("#{target}: no such tmux window. Nothing was done. Start one with session-start #{target} <dir>.")

    def agent!
      agent || Sessions.fail!(
        if pane!.shell?
          "#{target}: no Claude Code session runs in this window. Nothing was done. Start one with session-start #{target} <dir>."
        else
          "#{target}: the window runs #{pane!.command}, but no Claude Code session record in #{CLAUDE_DIR}/sessions matches it; " \
            "Claude Code may have changed that record. Nothing was done. Read the window with tmux capture-pane -p -t #{pane!.id}."
        end
      )
    end

    def screen = Screen.new(Sessions.tmux("capture-pane", "-p", "-e", "-t", pane!.id))

    def keys(*keys) = Sessions.tmux("send-keys", "-t", pane!.id, *keys)

    def submit(text)
      ready = screen
      Sessions.fail!("#{target}: the screen's layout isn't recognised, so nothing was typed. Read it with session-peek #{target}.") unless ready.recognised?
      Sessions.fail!("#{target}: the input box already holds typed text, so nothing was sent: #{ready.input.inspect}. Read it with session-peek #{target}.") if ready.typed?

      paste(text)
      Sessions.wait_until(TYPING_SECONDS) { screen.typed? } or
        Sessions.fail!("#{target}: the text never showed in the input box, so Enter was not pressed. Read it with session-peek #{target}.")
      keys("Enter")
      Sessions.wait_until(TYPING_SECONDS) { !screen.typed? }
    end

    def exit!(agent)
      unless agent.closable?
        wait = agent.idle? ? "Wait for the shell to finish" : "Stop its turn with session-stop #{target}, or wait"
        Sessions.fail!("#{target}: the session is #{agent.state}, so it was not closed. #{wait}; session-list shows when it is idle.")
      end

      driven = pane!
      submit("/exit")
      Sessions.wait_until(EXIT_SECONDS) { self.agent.nil? && Sessions.panes.find { |pane| pane.id == driven.id }&.shell? } or
        Sessions.fail!("#{target}: /exit was sent, but session #{agent.session_id} is still running after #{EXIT_SECONDS}s. Read it with session-peek #{target}.")
    end

    private

    def paste(text)
      buffer = "rpi-#{Process.pid}"
      Sessions.tmux("load-buffer", "-b", buffer, "-", stdin_data: text)
      Sessions.tmux("paste-buffer", "-p", "-d", "-b", buffer, "-t", pane!.id)
    end
  end
end
