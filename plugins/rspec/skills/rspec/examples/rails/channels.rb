# RSpec Rails: Channel Specs Examples
# Source: rspec-rails gem features/channel_specs/

# Channel specs test ActionCable channels.
# Location: spec/channels/

# Basic channel spec
RSpec.describe ChatChannel, type: :channel do
  describe "#subscribed" do
    it "successfully subscribes" do
      subscribe
      expect(subscription).to be_confirmed
    end

    it "rejects without authentication" do
      stub_connection current_user: nil
      subscribe
      expect(subscription).to be_rejected
    end
  end
end

# Testing with connection stub
RSpec.describe NotificationsChannel, type: :channel do
  let(:user) { create(:user) }

  before { stub_connection current_user: user }

  describe "#subscribed" do
    it "subscribes to user-specific stream" do
      subscribe

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(user)
    end
  end
end

# Testing streams
RSpec.describe RoomChannel, type: :channel do
  describe "#subscribed" do
    it "streams from room channel" do
      subscribe(room_id: 42)

      expect(subscription).to have_stream_from("room_42")
    end
  end

  describe "with model-based stream" do
    let(:room) { create(:room) }

    it "streams for the room" do
      subscribe(room_id: room.id)

      expect(subscription).to have_stream_for(room)
    end
  end
end

# Testing channel actions
RSpec.describe ChatChannel, type: :channel do
  let(:user) { create(:user) }
  let(:room) { create(:room) }

  before do
    stub_connection current_user: user
    subscribe(room_id: room.id)
  end

  describe "#speak" do
    it "broadcasts message to room" do
      expect {
        perform :speak, message: "Hello!"
      }.to have_broadcasted_to(room).with(
        user: user.name,
        message: "Hello!"
      )
    end
  end

  describe "#typing" do
    it "broadcasts typing status" do
      expect {
        perform :typing
      }.to have_broadcasted_to(room).with(
        user: user.name,
        typing: true
      )
    end
  end
end

# Testing subscription rejection
RSpec.describe PrivateChannel, type: :channel do
  describe "#subscribed" do
    context "when user lacks access" do
      let(:user) { create(:user) }
      let(:private_room) { create(:room, :private) }

      before { stub_connection current_user: user }

      it "rejects subscription" do
        subscribe(room_id: private_room.id)

        expect(subscription).to be_rejected
      end
    end

    context "when user has access" do
      let(:user) { create(:user, :admin) }
      let(:private_room) { create(:room, :private) }

      before { stub_connection current_user: user }

      it "confirms subscription" do
        subscribe(room_id: private_room.id)

        expect(subscription).to be_confirmed
      end
    end
  end
end

# Testing unsubscribe
RSpec.describe PresenceChannel, type: :channel do
  let(:user) { create(:user) }

  before { stub_connection current_user: user }

  describe "#unsubscribed" do
    it "broadcasts user left" do
      subscribe

      expect {
        unsubscribe
      }.to have_broadcasted_to("presence").with(
        action: "left",
        user: user.name
      )
    end
  end
end

# Testing connection
RSpec.describe ApplicationCable::Connection, type: :channel do
  describe "#connect" do
    context "with valid session" do
      let(:user) { create(:user) }

      before do
        cookies.signed[:user_id] = user.id
      end

      it "successfully connects" do
        connect

        expect(connection.current_user).to eq(user)
      end
    end

    context "without session" do
      it "rejects connection" do
        expect { connect }.to have_rejected_connection
      end
    end
  end
end

# Testing channel with parameters
RSpec.describe DocumentChannel, type: :channel do
  let(:user) { create(:user) }
  let(:document) { create(:document) }

  before { stub_connection current_user: user }

  describe "#subscribed with params" do
    it "uses provided document_id" do
      subscribe(document_id: document.id)

      expect(subscription).to have_stream_for(document)
    end
  end

  describe "#update" do
    before { subscribe(document_id: document.id) }

    it "broadcasts update to document stream" do
      expect {
        perform :update, content: "New content"
      }.to have_broadcasted_to(document).with(
        a_hash_including(content: "New content")
      )
    end
  end
end

# Testing broadcast matching
RSpec.describe "Broadcast matching", type: :channel do
  describe "matching broadcast content" do
    it "matches exact content" do
      expect {
        ActionCable.server.broadcast("test", { action: "update", data: 123 })
      }.to have_broadcasted_to("test").with(action: "update", data: 123)
    end

    it "matches with hash including" do
      expect {
        ActionCable.server.broadcast("test", { action: "update", data: 123, timestamp: Time.current })
      }.to have_broadcasted_to("test").with(a_hash_including(action: "update"))
    end

    it "matches with block" do
      expect {
        ActionCable.server.broadcast("test", { count: 5 })
      }.to have_broadcasted_to("test").with { |data|
        expect(data[:count]).to be > 0
      }
    end
  end
end

# Testing broadcast counts
RSpec.describe "Broadcast counts", type: :channel do
  it "matches exact broadcast count" do
    expect {
      3.times { ActionCable.server.broadcast("updates", { ping: true }) }
    }.to have_broadcasted_to("updates").exactly(3).times
  end

  it "matches at least count" do
    expect {
      5.times { ActionCable.server.broadcast("updates", { ping: true }) }
    }.to have_broadcasted_to("updates").at_least(:twice)
  end

  it "matches at most count" do
    expect {
      2.times { ActionCable.server.broadcast("updates", { ping: true }) }
    }.to have_broadcasted_to("updates").at_most(3).times
  end
end

# Testing no broadcast
RSpec.describe "No broadcast", type: :channel do
  it "verifies nothing was broadcast" do
    expect {
      # Some action that shouldn't broadcast
    }.not_to have_broadcasted_to("notifications")
  end
end
