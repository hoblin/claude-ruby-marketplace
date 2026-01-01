# RSpec Rails: Mailer Specs Examples
# Source: rspec-rails gem features/mailer_specs/

# Mailer specs test ActionMailer classes.
# Location: spec/mailers/

# Basic mailer spec
RSpec.describe NotificationsMailer, type: :mailer do
  describe "#signup" do
    let(:mail) { NotificationsMailer.signup }

    it "renders the headers" do
      expect(mail.subject).to eq("Signup")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Hi")
    end
  end
end

# Testing with dynamic recipient
RSpec.describe WelcomeMailer, type: :mailer do
  describe "#welcome" do
    let(:user) { create(:user, email: "john@example.com", name: "John") }
    let(:mail) { WelcomeMailer.welcome(user) }

    it "sends to the user email" do
      expect(mail.to).to eq(["john@example.com"])
    end

    it "personalizes the greeting" do
      expect(mail.body.encoded).to include("Hello John")
    end

    it "includes welcome link" do
      expect(mail.body.encoded).to include(dashboard_url)
    end
  end
end

# Testing multipart emails (HTML and text)
RSpec.describe NewsletterMailer, type: :mailer do
  describe "#weekly_digest" do
    let(:user) { create(:user) }
    let(:mail) { NewsletterMailer.weekly_digest(user) }

    it "has both HTML and text parts" do
      expect(mail.parts.length).to eq(2)
      expect(mail.parts.map(&:content_type)).to include(
        a_string_matching(/text\/plain/),
        a_string_matching(/text\/html/)
      )
    end

    describe "HTML part" do
      subject(:html_body) { mail.html_part.body.encoded }

      it "includes styled content" do
        expect(html_body).to include("<h1>")
        expect(html_body).to include("Weekly Digest")
      end
    end

    describe "text part" do
      subject(:text_body) { mail.text_part.body.encoded }

      it "includes plain text content" do
        expect(text_body).to include("Weekly Digest")
        expect(text_body).not_to include("<h1>")
      end
    end
  end
end

# Testing email with attachments
RSpec.describe ReportMailer, type: :mailer do
  describe "#monthly_report" do
    let(:mail) { ReportMailer.monthly_report }

    it "includes PDF attachment" do
      expect(mail.attachments.length).to eq(1)
      expect(mail.attachments.first.filename).to eq("report.pdf")
      expect(mail.attachments.first.content_type).to start_with("application/pdf")
    end
  end
end

# Testing delivery
RSpec.describe OrderMailer, type: :mailer do
  describe "#confirmation" do
    let(:order) { create(:order) }
    let(:mail) { OrderMailer.confirmation(order) }

    it "delivers email" do
      expect { mail.deliver_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "queues email for later delivery" do
      expect { mail.deliver_later }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end
  end
end

# send_email matcher (rspec-rails 7.0+)
RSpec.describe NotificationsMailer, type: :mailer do
  describe "#alert" do
    let(:user) { create(:user, email: "user@example.com") }

    it "sends email with correct attributes" do
      expect {
        NotificationsMailer.alert(user).deliver_now
      }.to send_email(
        from: "alerts@example.com",
        to: "user@example.com",
        subject: "Alert Notification"
      )
    end
  end
end

# Testing email previews exist (meta-test)
RSpec.describe "Mailer Previews" do
  it "has preview for WelcomeMailer" do
    expect(defined?(WelcomeMailerPreview)).to be_truthy
  end
end

# Testing with parameterized mailers (Rails 5.1+)
RSpec.describe NotificationsMailer, type: :mailer do
  describe "#with parameters" do
    let(:user) { create(:user) }
    let(:mail) do
      NotificationsMailer.with(user:, urgency: :high).important_update
    end

    it "uses parameterized values" do
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to include("[URGENT]")
    end
  end
end

# Testing email headers
RSpec.describe TransactionalMailer, type: :mailer do
  describe "#receipt" do
    let(:order) { create(:order) }
    let(:mail) { TransactionalMailer.receipt(order) }

    it "sets reply-to header" do
      expect(mail.reply_to).to eq(["support@example.com"])
    end

    it "sets custom headers" do
      expect(mail.headers["X-Transaction-ID"]).to eq(order.id.to_s)
    end

    it "sets high priority" do
      expect(mail.headers["X-Priority"]).to eq("1")
    end
  end
end

# Testing mailer with conditional content
RSpec.describe UserMailer, type: :mailer do
  describe "#password_reset" do
    let(:user) { create(:user) }
    let(:mail) { UserMailer.password_reset(user) }

    context "when user has two-factor enabled" do
      let(:user) { create(:user, :with_two_factor) }

      it "includes 2FA reminder" do
        expect(mail.body.encoded).to include("two-factor authentication")
      end
    end

    context "when user does not have two-factor" do
      it "does not mention 2FA" do
        expect(mail.body.encoded).not_to include("two-factor authentication")
      end
    end
  end
end

# Testing mailer callbacks
RSpec.describe AuditableMailer, type: :mailer do
  describe "after_action callback" do
    let(:mail) { AuditableMailer.system_notification }

    it "logs email delivery" do
      expect(EmailLog).to receive(:create!).with(
        mailer: "AuditableMailer",
        action: "system_notification"
      )

      mail.deliver_now
    end
  end
end

# Clearing deliveries between examples
RSpec.describe "Email delivery", type: :mailer do
  before { ActionMailer::Base.deliveries.clear }

  it "starts with empty deliveries" do
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "tracks delivered emails" do
    NotificationsMailer.signup.deliver_now
    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end
end

# Testing I18n in emails
RSpec.describe LocalizedMailer, type: :mailer do
  describe "#welcome" do
    let(:user) { create(:user, locale: "es") }
    let(:mail) { LocalizedMailer.welcome(user) }

    it "uses user locale" do
      expect(mail.subject).to eq("Bienvenido")
    end
  end
end
