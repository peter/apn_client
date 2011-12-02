require 'spec_helper'

require 'apn_client/message'

describe ApnClient::Message do
  before(:each) do
    @device_token = "7b7b8de5888bb742ba744a2a5c8e52c6481d1deeecc283e830533b7c6bf1d099"
    @alert = "Hello, check out version 9.5 of our awesome app in the app store"
    @badge = 3
  end

  describe "#initialize" do
    it "cannot be created without a token" do
      lambda {
        ApnClient::Message.new(1)
      }.should raise_error(/device_token/)
    end

    it "can be created with a token and an alert" do
      message = create_message(1, :device_token => @device_token, :alert => @alert)
      message.payload_hash.should == {'aps' => {'alert' => @alert}}
    end

    it "can be created with a token and an alert and a badge" do
      message = create_message(1, :device_token => @device_token, :alert => @alert, :badge => @badge)
      message.payload_hash.should == {'aps' => {'alert' => @alert, 'badge' => @badge}}
    end

    it "can be created with a token and an alert and a badge and content-available" do
      message = create_message(1,
        :device_token => @device_token,
        :alert => @alert,
        :badge => @badge,
        :content_available => true)
      message.payload_hash.should == {'aps' => {'alert' => @alert, 'badge' => @badge, 'content-available' => 1}}
    end

    it "raises an exception if payload_size exceeds 256 bytes" do
      lambda {
        too_long_alert = "A"*1000
        ApnClient::Message.new(1, :device_token => @device_token, :alert => too_long_alert)
      }.should raise_error(/payload/i)
    end
  end

  describe "#payload_size" do
    it "returns number of bytes in the payload"
  end

  def create_message(message_id, config = {})
    message = ApnClient::Message.new(message_id, config)
    message.message_id.should == 1
    [:device_token, :alert, :badge, :sound, :content_available].each do |attribute|
      message.send(attribute).should == config[attribute]
    end
    message.payload_size.should < 256
    message.to_s.should_not be_nil
    message
  end
end
