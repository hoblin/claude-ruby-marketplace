# RSpec Matchers: Output Examples
# Source: rspec-expectations gem features/built_in_matchers/output.feature

# output to stdout
RSpec.describe "output matcher - stdout" do
  describe "any output" do
    it "expects output to stdout" do
      expect { print "hello" }.to output.to_stdout
    end

    it "expects no output" do
      expect { 1 + 1 }.not_to output.to_stdout
    end
  end

  describe "specific output" do
    it "matches exact string" do
      expect { print "hello" }.to output("hello").to_stdout
    end

    it "matches with regex" do
      expect { puts "Hello, World!" }.to output(/World/).to_stdout
    end
  end
end

# output to stderr
RSpec.describe "output matcher - stderr" do
  it "captures stderr" do
    expect { warn "danger" }.to output.to_stderr
  end

  it "matches warning message" do
    expect { warn "danger" }.to output("danger\n").to_stderr
    expect { warn "danger" }.to output(/danger/).to_stderr
  end
end

# output from subprocesses
RSpec.describe "output matcher - any process" do
  it "captures subprocess stdout" do
    expect { system("echo hello") }.to output("hello\n").to_stdout_from_any_process
  end

  it "captures subprocess stderr" do
    expect { system("echo error >&2") }.to output("error\n").to_stderr_from_any_process
  end
end

# Practical examples
RSpec.describe Logger do
  subject(:logger) { build(:logger, output: $stdout) }

  describe "#info" do
    it "outputs formatted message to stdout" do
      expect { logger.info("test message") }
        .to output(/\[INFO\].*test message/).to_stdout
    end
  end

  describe "#error" do
    it "outputs to stderr" do
      expect { logger.error("critical failure") }
        .to output(/critical failure/).to_stderr
    end
  end
end

RSpec.describe CLI do
  subject(:cli) { build(:cli) }

  describe "#run" do
    context "with --help flag" do
      it "prints usage to stdout" do
        expect { cli.run(["--help"]) }
          .to output(/Usage:/).to_stdout
      end
    end

    context "with invalid option" do
      it "prints error to stderr" do
        expect { cli.run(["--invalid"]) }
          .to output(/unknown option/).to_stderr
      end
    end

    context "in verbose mode" do
      it "prints progress information" do
        expect { cli.run(["--verbose", "process"]) }
          .to output(/Processing/).to_stdout
      end
    end
  end
end

RSpec.describe RakeTask do
  describe "external command execution" do
    it "captures output from system calls" do
      expect { system("rake db:migrate") }
        .to output(/migrated/).to_stdout_from_any_process
    end
  end
end
