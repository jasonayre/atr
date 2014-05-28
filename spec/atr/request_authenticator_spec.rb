require 'spec_helper'
require 'ostruct'

describe ::Atr::RequestAuthenticator do
  let(:fake_request) {
    OpenStruct.new(:url => "user/1234")
  }

  subject {
    described_class.new(fake_request)
  }

  describe "#new" do
    its(:request) { should eq fake_request }
  end

  context "by default" do
    its(:matches?) { should be_false }
  end
end