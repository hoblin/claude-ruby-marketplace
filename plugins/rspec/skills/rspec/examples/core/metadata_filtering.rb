# RSpec Core: Metadata and Filtering Examples
# Source: rspec-core gem features/filtering/*.feature

# Adding metadata to examples
RSpec.describe "API" do
  it "handles fast requests", :fast do
  end

  it "handles slow requests", :slow, timeout: 30 do
  end

  it "requires authentication", authorized: true do
  end
end

# Adding metadata to groups
RSpec.describe PaymentGateway, :integration, :external do
  it "processes payment" do
  end
end

# Accessing metadata in examples
RSpec.describe "Metadata access" do
  it "can read its own metadata" do |example|
    expect(example.metadata[:description]).to eq("can read its own metadata")
    expect(example.metadata[:file_path]).to include("_spec.rb")
  end
end

# Focus filtering - run only focused examples
RSpec.configure do |config|
  config.filter_run_when_matching :focus
end

RSpec.describe "Debugging" do
  it "skipped example" do
  end

  fit "focused example - only this runs" do  # fit = it with :focus
  end

  it "another skipped example" do
  end
end

# Exclusion filtering
RSpec.configure do |config|
  config.filter_run_excluding :slow
  config.filter_run_excluding broken: true
end

RSpec.describe "Suite" do
  it "runs normally" do
  end

  it "skipped - marked slow", :slow do
  end

  it "skipped - marked broken", broken: true do
  end
end

# Skip and pending
RSpec.describe "Skip examples" do
  xit "skipped with xit" do
  end

  it "skipped with skip call" do
    skip "Not implemented yet"
  end

  it "skipped via metadata", skip: "Waiting on API" do
  end
end

RSpec.describe "Pending examples" do
  it "pending - expected to fail" do
    pending "Waiting for feature X"
    expect(1 + 1).to eq(3)  # Fails, but marked pending
  end

  # If pending test passes, RSpec fails it (unexpected pass)
end

# Conditional hooks with metadata
RSpec.configure do |config|
  config.before(:example, :db) do
    DatabaseCleaner.start
  end

  config.after(:example, :db) do
    DatabaseCleaner.clean
  end

  config.around(:example, :vcr) do |example|
    VCR.use_cassette(example.metadata[:description]) do
      example.run
    end
  end
end

RSpec.describe UserService, :db do
  it "creates user" do  # DatabaseCleaner runs automatically
    expect { UserService.create(name: "Alice") }.to change(User, :count).by(1)
  end
end

RSpec.describe ExternalAPI, :vcr do
  it "fetches data" do  # VCR cassette used automatically
    response = ExternalAPI.fetch
    expect(response).to be_success
  end
end

# Aggregate failures - continue after first failure
RSpec.describe "Response validation" do
  it "validates all response fields" do
    response = Client.make_request

    aggregate_failures "response validation" do
      expect(response.status).to eq(200)
      expect(response.headers).to include("Content-Type" => "application/json")
      expect(response.body).to include("success")
      # All expectations run, failures collected
    end
  end
end

# Aggregate failures via metadata
RSpec.describe Client, :aggregate_failures do
  it "validates response" do
    response = Client.make_request
    expect(response.status).to eq(200)
    expect(response.body).to include("success")
    # Both run even if first fails
  end
end

# Global aggregate failures
RSpec.configure do |config|
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end
end
