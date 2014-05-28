require 'spec_helper'

describe ::Atr::Publisher do
  ::Fake::Blog::Post.class_eval do
    include ::Atr::Publishable
  end

  before do
    ::Atr::Redis.connect unless ::Atr::Redis.connected?

    ::Atr::Publisher.supervise_as :atr_publisher
  end

  let(:fake_record) { ::Fake::Blog::Post.new }
  let(:event_name) { "fake.blog.post.created"}
  let(:routing_key) { "fake.blog.post.created" }
  let(:record_created_routing_key) { "fake.blog.post.created" }
  let(:record_updated_routing_key) { "fake.blog.post.updated" }
  let(:record_destroyed_routing_key) { "fake.blog.post.destroyed" }

  let(:fake_event) {
    ::Atr::Event.new(routing_key, event_name, fake_record)
  }

  subject {
   ::Atr::Publisher.supervise_as :atr_publisher
   ::Celluloid::Actor[:atr_publisher]
  }

  describe "#publish_event" do
    it "should receive publish event with instance of event when publishable record is saved" do
      subject.should_receive(:publish_event).with(instance_of(::Atr::Event))

      fake_record.save
    end

    it "should publish via redis connection" do
      ::Atr::Redis.connection.should_receive(:publish).with(routing_key, Marshal.dump(fake_event))

      subject.publish_event(fake_event)
    end
  end
end