# RSpec Rails: Job Specs Examples
# Source: rspec-rails gem features/job_specs/

# Job specs test ActiveJob classes.
# Requires: ActiveJob::Base.queue_adapter = :test
# Location: spec/jobs/

# Basic job spec
RSpec.describe UploadBackupsJob, type: :job do
  describe "#perform_later" do
    it "enqueues the job" do
      expect {
        UploadBackupsJob.perform_later("backup.sql")
      }.to have_enqueued_job
    end

    it "enqueues with correct arguments" do
      expect {
        UploadBackupsJob.perform_later("backup.sql")
      }.to have_enqueued_job.with("backup.sql")
    end
  end
end

# Testing on specific queue
RSpec.describe EmailDeliveryJob, type: :job do
  describe "#perform_later" do
    it "enqueues on the mailers queue" do
      expect {
        EmailDeliveryJob.perform_later
      }.to have_enqueued_job.on_queue("mailers")
    end
  end
end

# Testing scheduled jobs
RSpec.describe ScheduledReportJob, type: :job do
  describe "#perform_later" do
    it "enqueues at specific time" do
      scheduled_time = 1.day.from_now.noon

      expect {
        ScheduledReportJob.set(wait_until: scheduled_time).perform_later
      }.to have_enqueued_job.at(scheduled_time)
    end

    it "enqueues with wait duration" do
      expect {
        ScheduledReportJob.set(wait: 1.hour).perform_later
      }.to have_enqueued_job.at(a_value_within(1.second).of(1.hour.from_now))
    end
  end
end

# Testing job priority
RSpec.describe HighPriorityJob, type: :job do
  describe "#perform_later" do
    it "enqueues with priority" do
      expect {
        HighPriorityJob.set(priority: 1).perform_later
      }.to have_enqueued_job.at_priority(1)
    end
  end
end

# Imperative (post-hoc) syntax
RSpec.describe ProcessOrderJob, type: :job do
  describe "#perform_later" do
    let(:order) { create(:order) }

    before { ProcessOrderJob.perform_later(order) }

    it "has been enqueued" do
      expect(ProcessOrderJob).to have_been_enqueued
    end

    it "was enqueued exactly once" do
      expect(ProcessOrderJob).to have_been_enqueued.exactly(:once)
    end
  end
end

# Testing job execution count
RSpec.describe BatchProcessingJob, type: :job do
  describe "multiple enqueues" do
    it "enqueues exactly 3 times" do
      expect {
        3.times { BatchProcessingJob.perform_later }
      }.to have_enqueued_job.exactly(3).times
    end

    it "enqueues at least twice" do
      expect {
        5.times { BatchProcessingJob.perform_later }
      }.to have_enqueued_job.at_least(:twice)
    end
  end
end

# Testing job perform behavior
RSpec.describe SendNotificationJob, type: :job do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:message) { "Hello!" }

    it "sends notification to user" do
      notifier = instance_double(NotificationService)
      allow(NotificationService).to receive(:new).and_return(notifier)
      expect(notifier).to receive(:notify).with(user, message)

      SendNotificationJob.perform_now(user, message)
    end
  end
end

# Testing with perform_enqueued_jobs
RSpec.describe "Job execution", type: :job do
  describe "running enqueued jobs" do
    let(:user) { create(:user) }

    it "performs jobs inline" do
      perform_enqueued_jobs do
        WelcomeEmailJob.perform_later(user)
      end

      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it "performs only specific jobs" do
      perform_enqueued_jobs(only: WelcomeEmailJob) do
        WelcomeEmailJob.perform_later(user)
        CleanupJob.perform_later
      end

      expect(WelcomeEmailJob).not_to have_been_enqueued
      expect(CleanupJob).to have_been_enqueued
    end
  end
end

# Testing job with retries
RSpec.describe RetryableJob, type: :job do
  describe "retry behavior" do
    let(:api_client) { instance_double(ExternalApi) }

    before do
      allow(ExternalApi).to receive(:new).and_return(api_client)
    end

    context "when API fails temporarily" do
      before do
        call_count = 0
        allow(api_client).to receive(:call) do
          call_count += 1
          raise StandardError if call_count < 3
          :success
        end
      end

      it "retries and eventually succeeds" do
        expect {
          perform_enqueued_jobs { RetryableJob.perform_later }
        }.not_to raise_error
      end
    end
  end
end

# Testing job that spawns other jobs
RSpec.describe ParentJob, type: :job do
  describe "#perform" do
    let(:items) { create_list(:item, 3) }

    it "enqueues child job for each item" do
      expect {
        ParentJob.perform_now(items.map(&:id))
      }.to have_enqueued_job(ChildJob).exactly(3).times
    end
  end
end

# Testing with specific job class
RSpec.describe "Multiple job types", type: :job do
  describe "selective matching" do
    it "matches specific job class" do
      expect {
        SendEmailJob.perform_later
        ProcessPaymentJob.perform_later
      }.to have_enqueued_job(SendEmailJob)
        .and have_enqueued_job(ProcessPaymentJob)
    end
  end
end

# Testing job with complex arguments using block
RSpec.describe DataExportJob, type: :job do
  describe "#perform_later" do
    it "enqueues with expected structure" do
      expect {
        DataExportJob.perform_later(
          user_id: 1,
          format: :csv,
          filters: { status: :active }
        )
      }.to have_enqueued_job.with { |args|
        expect(args[:user_id]).to eq(1)
        expect(args[:format]).to eq(:csv)
        expect(args[:filters]).to include(status: :active)
      }
    end
  end
end

# Testing job queue adapter configuration
RSpec.describe "Queue adapter", type: :job do
  it "uses test adapter" do
    expect(ActiveJob::Base.queue_adapter).to be_a(ActiveJob::QueueAdapters::TestAdapter)
  end
end

# Clearing enqueued jobs between examples
RSpec.describe "Job queue state", type: :job do
  before { clear_enqueued_jobs }

  it "starts with empty queue" do
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to be_empty
  end
end

# Testing that no jobs were enqueued
RSpec.describe ConditionalJob, type: :job do
  describe "#perform" do
    context "when condition is not met" do
      let(:order) { create(:order, :complete) }

      it "does not enqueue follow-up job" do
        expect {
          ConditionalJob.perform_now(order)
        }.not_to have_enqueued_job(FollowUpJob)
      end
    end
  end
end

# Testing job with GlobalID arguments
RSpec.describe ProcessRecordJob, type: :job do
  describe "#perform" do
    let(:record) { create(:widget) }

    it "accepts ActiveRecord objects" do
      expect {
        ProcessRecordJob.perform_later(record)
      }.to have_enqueued_job.with(record)
    end
  end
end
