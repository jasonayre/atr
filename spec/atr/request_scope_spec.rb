require 'spec_helper'
require 'ostruct'

describe ::Atr::RequestScope do
  let(:fake_request) {
    OpenStruct.new(:query_string => "user=1234")
  }
  let(:expected_params) {
    {
      "user" => "1234"
    }
  }

  subject {
    described_class.new(fake_request)
  }

  its(:request) { should eq fake_request }
  its(:matches?) { should be_false }
  its(:params) { should eq expected_params }
end