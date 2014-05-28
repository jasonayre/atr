require 'spec_helper'

describe ::Atr::Redis do
  subject { described_class }

  describe ".connect" do
    it "should connect to redis using celluloid driver" do
      ::Redis.should_receive(:new).with(:driver => :celluloid)

      subject.connect
    end
  end
end