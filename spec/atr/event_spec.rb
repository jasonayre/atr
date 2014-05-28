require 'spec_helper'

describe ::Atr::Event do
  let(:fake_record) { ::Fake::Blog::Post.new }
  let(:event_name) { "fake.blog.post.created"}
  subject {
    ::Atr::Event.new("fake.blog.post.created", event_name, fake_record)
  }

  before do
    subject.stub(:id).and_return("something")
  end

  its(:id) { should eq "something" }
  its(:name) { should eq "fake.blog.post.created" }
  its(:record) { should eq fake_record.attributes }

  context "serialization" do
    it "should serialize into javascript parseable json" do
      subject.to_json.should include "{\"id\":\"something\",\"name\":\"fake.blog.post.created\","
    end
  end
end