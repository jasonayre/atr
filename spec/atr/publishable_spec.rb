require 'spec_helper'
require 'atr/publishable'
describe ::Atr::Publishable do
  ::Fake::Blog::Post.class_eval do
    include ::Atr::Publishable
    publication_scope :user_id
  end

  before do
    ::Atr::Redis.connect unless ::Atr::Redis.connected?

    ::Atr.stub(:publish_event)
  end

  let(:fake_blog_post_attributes) {
    {
      :user_id => 123
    }
  }

  let(:fake_blog_post) { ::Fake::Blog::Post.new(fake_blog_post_attributes) }

  subject { fake_blog_post }

  context "create" do
    it "should publish create event" do
      Atr.should_receive(:publish_event).with(instance_of(::Atr::Event))
      subject.save
    end
  end

  context "update" do
    it "should publish updated event" do

      Atr.should_receive(:publish_event).with(instance_of(::Atr::Event))
      subject.save
      subject.update_attributes(:title => "something else")
    end
  end


  context "destroy" do
    it "should publish destroy event" do
      Atr.should_receive(:publish_event).with(instance_of(::Atr::Event))
      subject.destroy
    end
  end

  context "Class Methods" do
    subject{ ::Fake::Blog::Post }

    its(:publishable_actions) { should be_an(Array) }

    its(:resource_routing_keys) { should include("fake", "blog", "post")}

    describe ".build_publication_scope_for_record" do
      it "should build record scoped to user id" do
        subject.build_publication_scope_for_record(fake_blog_post).should eq ["user", 123]
      end
    end
  end
end
