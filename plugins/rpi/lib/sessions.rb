# frozen_string_literal: true

require "json"
require "open3"
require "time"

module Sessions
  CLAUDE = File.join(Dir.home, ".claude")
  SESSION2MD = File.expand_path("../bin/session2md", __dir__)
  SHELLS = %w[bash zsh fish sh dash ksh].freeze
  PANE_FORMAT = "\#{session_name}\t\#{window_name}\t\#{pane_id}\t\#{pane_current_command}\t\#{session_name}:\#{window_id}.\#{pane_id}"
  ANSI = /\e\[[\d;]*m|\e\]8;[^\e]*\e\\/
  DIM = "\e[2m"
  PROMPT = "❯"
  RULE = /\A─+(?: .+ ─+)?\z/
  COMMAND_NAME = %r{<command-name>([^<]+)</command-name>}
  COMMAND_ARGS = %r{<command-args>([^<]*)</command-args>}
  PREVIEW_CHARS = 100
  POLL_SECONDS = 0.2

  module_function

  def fail!(message)
    abort "#{File.basename($PROGRAM_NAME)}: #{message}"
  end

  def tmux(*args, **options)
    out, status = Open3.capture2e("tmux", *args, **options)
    fail!("tmux #{args.first}: #{out.strip}") unless status.success?
    out
  end

  def panes
    out, status = Open3.capture2e("tmux", "list-panes", "-a", "-F", PANE_FORMAT)
    return [] unless status.success?

    out.lines.map do |line|
      project, clone, id, command, address = line.chomp.split("\t")
      Pane.new(target: Target.new(project, clone), id:, command:, address:)
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

  Target = Data.define(:project, :clone) do
    def self.parse(text)
      project, clone = text.to_s.split(":", 2)
      valid = [project, clone].all? { it.to_s.match?(/\A[\w.-]+\z/) }
      Sessions.fail!("name the session as <project>:<clone>, e.g. vibemetrics-api:two, not #{text.inspect}") unless valid
      new(project, clone)
    end

    def name = "#{project}-#{clone}"

    def to_s = "#{project}:#{clone}"
  end

  Pane = Data.define(:target, :id, :command, :address) do
    def shell? = SHELLS.include?(command)
  end

  Agent = Data.define(:pid, :session_id, :cwd, :status, :waiting_for, :version, :pane) do
    def self.all
      Dir[File.join(CLAUDE, "sessions", "*.json")].filter_map do |file|
        next unless File.basename(file, ".json").match?(/\A\d+\z/)

        record = JSON.parse(File.read(file))
        next if record["tmux"].to_s.empty? || !alive?(record["pid"])

        new(pid: record["pid"], session_id: record["sessionId"], cwd: record["cwd"], status: record["status"],
          waiting_for: record["waitingFor"], version: record["version"], pane: record["tmux"])
      rescue JSON::ParserError, Errno::ENOENT
        nil
      end
    end

    def self.alive?(pid)
      Process.kill(0, pid)
      true
    rescue Errno::ESRCH, TypeError
      false
    end

    def idle? = %w[idle shell].include?(status)

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
      @path = File.join(CLAUDE, "projects", agent.cwd.gsub(/[^A-Za-z0-9]/, "-"), "#{agent.session_id}.jsonl")
    end

    def entries
      @entries ||= File.file?(path) ? File.foreach(path).with_index(1).filter_map { |line, number| parse(line, number) } : []
    end

    def last_at = at(entries.reverse_each.find { it["timestamp"] })

    def run_started_at = at(entries.reverse_each.find { it["type"] == "user" && it["turnOrigin"] })

    def ask = entries.reverse_each.find { %w[human peer].include?(it.dig("origin", "kind")) }

    def last_ask
      entry = ask or return
      entry.dig("origin", "body") || text(entry.dig("message", "content"))
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

    def reply = entries.reverse_each.find { it["type"] == "assistant" }

    def parse(line, number)
      JSON.parse(line).merge("line" => number)
    rescue JSON::ParserError
      nil
    end

    def at(entry) = entry && Time.iso8601(entry["timestamp"])

    def text(content)
      return Array(content).filter_map { it["text"] }.join(" ") unless content.is_a?(String)

      name = content[COMMAND_NAME, 1] or return content
      [name, content[COMMAND_ARGS, 1]].compact.map(&:strip).reject(&:empty?).join(" ")
    end
  end

  class Screen
    def initialize(raw)
      @raw = raw.lines.map(&:chomp)
      @plain = @raw.map { it.gsub(ANSI, "").tr(" ", " ").rstrip }
      @top = @plain.each_index.reverse_each.find { |row| @plain[row].match?(RULE) && @plain[row + 1].to_s.start_with?(PROMPT) }
      @bottom = @top && ((@top + 2)...@plain.size).find { @plain[it].match?(RULE) }
    end

    def recognised? = !@bottom.nil?

    def input = @plain[(@top + 1)...@bottom].join("\n").delete_prefix(PROMPT).strip

    def box
      return :empty if input.empty?

      leading = @raw[@top + 1].split(PROMPT, 2).last.sub(/\A[  ]/, "")[/\A(?:\e\[[\d;]*m)*/]
      leading.include?(DIM) ? :suggestion : :typed
    end

    def activity = @plain[0...@top].reject(&:empty?).last(6)

    def status = @plain[(@bottom + 1)..].reject(&:empty?)

    def text = @plain.reject(&:empty?)
  end

  class Window
    attr_reader :target

    def initialize(target)
      @target = target
    end

    def pane = Sessions.panes.find { it.target == target }

    def pane! = pane || Sessions.fail!("#{target}: no such tmux window. Nothing was done. Start one with session-start #{target} <dir>.")

    def agent
      found = pane or return
      Agent.all.find { it.pane == found.address }
    end

    def closed? = agent.nil? && pane!.shell?

    def agent! = agent || Sessions.fail!("#{target}: no Claude Code session runs in this window. Nothing was done. Start one with session-start #{target} <dir>.")

    def screen = Screen.new(Sessions.tmux("capture-pane", "-p", "-e", "-t", pane!.id))

    def keys(*keys) = Sessions.tmux("send-keys", "-t", pane!.id, *keys)

    def submit(text)
      ready = screen
      Sessions.fail!("#{target}: the screen's layout isn't recognised, so nothing was typed. Read it with session-peek #{target}.") unless ready.recognised?
      Sessions.fail!("#{target}: the input box already holds typed text, so nothing was sent: #{ready.input.inspect}. Read it with session-peek #{target}.") if ready.box == :typed

      paste(text)
      Sessions.wait_until(3) { screen.then { it.recognised? && it.box == :typed } } or Sessions.fail!("#{target}: the text never showed in the input box, so Enter was not pressed. Read it with session-peek #{target}.")
      keys("Enter")
      Sessions.wait_until(3) { screen.then { !it.recognised? || it.box != :typed } }
    end

    private

    def paste(text)
      buffer = "rpi-#{Process.pid}"
      Sessions.tmux("load-buffer", "-b", buffer, "-", stdin_data: text)
      Sessions.tmux("paste-buffer", "-p", "-d", "-b", buffer, "-t", pane!.id)
    end
  end
end
