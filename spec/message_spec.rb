require 'spec_helper'

describe ApnClient::Message do
  before(:each) do
    @device_token = "7b7b8de5888bb742ba744a2a5c8e52c6481d1deeecc283e830533b7c6bf1d099"
    @other_device_token = "8c7b8de5888bb742ba744a2a5c8e52c6481d1deeecc283e830533b7c6bf5e699"
    @alert = "Hello, check out version 9.5 of our awesome app in the app store"
    @badge = 3
  end

  describe "#initialize" do
    it "cannot be created without a message_id" do
      lambda {
        ApnClient::Message.new()
      }.should raise_error(/message_id/)
    end

    it "cannot be created without a token" do
      lambda {
        ApnClient::Message.new(:message_id => 1)
      }.should raise_error(/device_token/)
    end

    it "can be created with a token and an alert" do
      message = create_message(:message_id => 1, :device_token => @device_token, :alert => @alert)
      message.payload_hash.should == {'aps' => {'alert' => @alert}}
    end

    it "can be created with a token and an alert and a badge" do
      message = create_message(:message_id => 1, :device_token => @device_token, :alert => @alert, :badge => @badge)
      message.payload_hash.should == {'aps' => {'alert' => @alert, 'badge' => @badge}}
    end

    it "can be created with a token and an alert and a badge and content-available" do
      message = create_message(
        :message_id => 1,
        :device_token => @device_token,
        :alert => @alert,
        :badge => @badge,
        :content_available => true)
      message.payload_hash.should == {'aps' => {'alert' => @alert, 'badge' => @badge, 'content-available' => 1}}
    end

    it "raises an exception if payload_size exceeds 256 bytes" do
      lambda {
        too_long_alert = "A"*1000
        ApnClient::Message.new(:message_id => 1, :device_token => @device_token, :alert => too_long_alert)
      }.should raise_error(/payload/i)
    end
  end

  describe "attribute accessors" do
    it "works with symbol keys" do
      message = create_message(
        :message_id => 1,
        :device_token => @device_token,
        :alert => @alert,
        :badge => @badge,
        :content_available => true)
      message.message_id.should == 1
      message.badge.should == @badge
      message.message_id = 3
      message.message_id.should == 3
    end
    
    it "works with string keys too" do
      message = create_message(
        'message_id' => 1,
        'device_token' => @device_token,
        'alert' => @alert,
        'badge' => @badge,
        'content_available' => true)
      message.message_id.should == 1
      message.badge.should == @badge
      message.message_id = 3
      message.message_id.should == 3
      message.attributes.should == {
        :message_id => 3,
        :device_token => @device_token,
        :alert => @alert,
        :badge => @badge,
        :content_available => true        
      }
    end
  end

  describe "#==" do
    before(:each) do
      @message = create_message(:message_id => 3, :device_token => @device_token)
      @other_message = create_message(:message_id => 5, :device_token => @other_device_token)
    end
    
    it "returns false for nil" do
      @message.should_not == nil
    end
    
    it "returns false for an object that is not a Message" do      
      @message.should_not == "foobar"
    end
    
    it "returns false for a Message with a different message_id" do
      @message.should_not == @other_message
    end
    
    it "returns true for a Message with the same message_id" do
      @other_message.message_id = @message.message_id
      @message.should == @other_message
    end
  end

  describe "#to_hash" do
    it "returns a hash with the attributes of the message" do
      attributes = {
        :message_id => 1,
        :device_token => @device_token,
        :alert => @alert,
        :badge => @badge,
        :content_available => true
      }
      message = create_message(attributes)
      message.to_hash.should == attributes
    end
  end

  describe "#to_json" do
    it "converts the attributes hash to JSON" do
      attributes = {
        :message_id => 1,
        :device_token => @device_token,
        :alert => @alert,
        :badge => @badge,
        :content_available => true
      }
      message = create_message(attributes)
      message.to_hash.should == attributes
      JSON.parse(message.to_json).should == {
        'message_id' => 1,
        'device_token' => @device_token,
        'alert' => @alert,
        'badge' => @badge,
        'content_available' => true
      }
    end
  end

  def create_message(attributes = {})
    message = ApnClient::Message.new(attributes)
    attributes.keys.each do |attribute|
      message.send(attribute).should == attributes[attribute]
    end
    message.payload_size.should < 256
    message.to_s.should_not be_nil
    message
  end
end
