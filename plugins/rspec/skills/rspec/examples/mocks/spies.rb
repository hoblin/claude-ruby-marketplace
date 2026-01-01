# RSpec Mocks: Spies Examples
# Source: rspec-mocks gem features/basics/spies.feature,
#         null_object_doubles.feature

# spy - null object double for arrange-act-assert pattern
RSpec.describe "spy" do
  describe "basic usage" do
    it "allows any message without raising" do
      invitation = spy("invitation")
      invitation.deliver  # doesn't raise
      invitation.foo.bar.baz  # also doesn't raise
    end

    it "verifies messages after the fact" do
      invitation = spy("invitation")
      invitation.deliver("user@example.com")

      expect(invitation).to have_received(:deliver).with("user@example.com")
    end
  end

  describe "verifying doubles as spies" do
    it "can create instance spy" do
      user = instance_spy("User")
      user.save
      expect(user).to have_received(:save)
    end

    it "can create class spy" do
      notifier = class_spy("UserMailer")
      notifier.send_welcome("email@example.com")
      expect(notifier).to have_received(:send_welcome)
    end

    it "can create object spy" do
      real_user = User.new
      user = object_spy(real_user)
      user.save
      expect(user).to have_received(:save)
    end
  end

  describe "spy constraints" do
    it "verifies call count" do
      invitation = spy("invitation")
      invitation.deliver
      invitation.deliver

      expect(invitation).to have_received(:deliver).twice
    end

    it "verifies message order" do
      invitation = spy("invitation")
      invitation.prepare
      invitation.deliver

      expect(invitation).to have_received(:prepare).ordered
      expect(invitation).to have_received(:deliver).ordered
    end

    it "verifies arguments" do
      invitation = spy("invitation")
      invitation.deliver("foo@example.com")
      invitation.deliver("bar@example.com")

      expect(invitation).to have_received(:deliver).with("foo@example.com")
      expect(invitation).to have_received(:deliver).with("bar@example.com")
    end
  end
end

# Practical example: arrange-act-assert with spies
RSpec.describe InvitationService do
  subject(:service) { build(:invitation_service, mailer:) }

  let(:mailer) { spy("mailer") }
  let(:user) { build(:user, email: "test@example.com") }

  describe "#send_invitation" do
    it "sends email to the user" do
      # Arrange (done in let blocks)

      # Act
      service.send_invitation(user)

      # Assert
      expect(mailer).to have_received(:deliver).with(user.email)
    end

    it "sends invitation with correct template" do
      service.send_invitation(user)

      expect(mailer).to have_received(:deliver)
        .with(user.email)
        .once
    end
  end
end

# null object double
RSpec.describe "null object double" do
  describe "as_null_object" do
    it "returns itself for any message" do
      dbl = double("collaborator").as_null_object
      expect(dbl.foo.bar.baz).to be(dbl)
    end

    it "can have specific stubs" do
      dbl = double("collaborator", foo: 3).as_null_object
      allow(dbl).to receive(:bar).and_return(4)

      expect(dbl.foo).to eq(3)
      expect(dbl.bar).to eq(4)
      expect(dbl.undefined_method).to be(dbl)
    end
  end
end

# Practical use: chained methods without full stubbing
RSpec.describe QueryBuilder do
  subject(:builder) { build(:query_builder) }

  let(:query) { instance_spy("ActiveRecord::Relation").as_null_object }

  describe "#build" do
    before { allow(User).to receive(:where).and_return(query) }

    it "chains query methods" do
      builder.build(status: :active, role: :admin)

      expect(query).to have_received(:where).with(status: :active)
      expect(query).to have_received(:where).with(role: :admin)
    end
  end
end

# Partial doubles with spies
RSpec.describe "partial double spy pattern" do
  describe "spying on real objects" do
    it "allows spying on class methods" do
      allow(Invitation).to receive(:deliver)

      Invitation.deliver("test@example.com")

      expect(Invitation).to have_received(:deliver).with("test@example.com")
    end
  end
end

