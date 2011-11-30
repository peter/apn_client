require 'spec_helper'

require 'apn_client/connection'

describe ApnClient::Connection do
  describe "#initialize" do
    it "accepts a config hash"
    it "allows the config hash to have string keys"
    it "does not accept a config hash with invalid keys"
  end
  
  describe ".valid_config_keys" do
    it "returns a list of keys that are allowed to be in the config hash" do
      ApnClient::Connection.valid_config_keys.should == [:host, :port, :certificate, :certificate_passphrase]
    end
  end
end
