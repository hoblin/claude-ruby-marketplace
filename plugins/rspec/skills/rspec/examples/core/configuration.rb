# RSpec Core: Configuration Examples
# Source: rspec-core gem spec/spec_helper.rb, features/configuration/*.feature

# Full spec_helper.rb configuration
RSpec.configure do |config|
  # Expectations configuration
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.max_formatted_output_length = 1000
  end

  # Mocks configuration
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Execution order
  config.order = :random
  Kernel.srand config.seed

  # Failure handling
  config.fail_fast = false  # or number like 3

  # Focus filtering - run only focused tests when any exist
  config.filter_run_when_matching :focus

  # Persist example status for --only-failures
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Output formatting
  config.default_formatter = "doc" if config.files_to_run.one?

  # Profile slow examples
  config.profile_examples = 10

  # Disable monkey patching (no should syntax)
  config.disable_monkey_patching!

  # Warnings
  config.raise_errors_for_deprecations!
end

# Including modules conditionally
RSpec.configure do |config|
  # Include everywhere
  config.include FactoryBot::Syntax::Methods

  # Include only in specific types
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Capybara::DSL, type: :feature

  # Include based on metadata
  config.include ApiHelpers, :api
  config.include AuthHelpers, :authorized
end

# Extending example groups
RSpec.configure do |config|
  config.extend ControllerMacros, type: :controller
end

# Custom type inference
RSpec.configure do |config|
  config.infer_spec_type_from_file_location!

  config.define_derived_metadata(file_path: %r{/spec/api/}) do |metadata|
    metadata[:type] = :request
  end
end

# Shared context auto-inclusion
RSpec.configure do |config|
  config.include_context "authenticated user", :authenticated
  config.include_context "with admin", :admin
end

# Filter by Ruby version
RSpec.configure do |config|
  config.filter_run_excluding ruby: ->(version) {
    case version.to_s
    when "!jruby"
      RUBY_ENGINE == "jruby"
    when /^> (.*)/
      !(RUBY_VERSION.to_s > $1)
    else
      !(RUBY_VERSION.to_s =~ /^#{version}/)
    end
  }
end

# Example:
it "uses Ruby 3.2 feature", ruby: "> 3.2" do
end

# Alias it_behaves_like for readability
RSpec.configure do |config|
  config.alias_it_behaves_like_to :it_has_behavior
  config.alias_it_behaves_like_to :it_should_behave_like
end

# Around hooks for specific metadata
RSpec.configure do |config|
  config.around(:example, :freeze_time) do |example|
    travel_to(Time.zone.local(2024, 1, 1)) do
      example.run
    end
  end

  config.around(:example, :isolated_directory) do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end
end

# .rspec file example
# --format documentation
# --color
# --require spec_helper
# --order random
# --profile 10

# .rspec-local (gitignored, personal preferences)
# --fail-fast
# --format progress
