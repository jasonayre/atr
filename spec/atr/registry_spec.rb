require 'spec_helper'

describe ::Atr::Registry do
  ::Fake::Blog::Post.class_eval do
    include ::Atr::Publishable
    publication_scope :user_id
  end

  subject{ described_class }

  let(:expected_channels) {
    ["fake.blog.post.created", "fake.blog.post.updated", "fake.blog.post.destroyed"]
  }
  let(:user_id) { 1234 }
  let(:scoped_routing_key) { "user.#{user_id}"}
  let(:expected_scoped_channels) {
    expected_channels.map{|channel| "#{scoped_routing_key}.#{channel}"}
  }

  its(:channels) { should include *expected_channels}

  describe ".scoped_channels" do
    it "should scope channels by routing key passed in" do
      described_class.scoped_channels(scoped_routing_key).should include *expected_scoped_channels
    end
  end
end