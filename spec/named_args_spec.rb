require 'spec_helper'

describe ApnClient::NamedArgs do
  describe ".assert_allowed!" do
    it "raises an exception if the argument hash contains a key not in the allowed list" do
      lambda {
        ApnClient::NamedArgs.assert_allowed!({:foo => 1, :bla => 2}, [:foo, :bar])
      }.should raise_error(/foo/)
    end

    it "does not raise an exception if the arguments hash is empty" do
      ApnClient::NamedArgs.assert_allowed!({}, [:foo, :bar])
    end

    it "does not raise an exception if all allowed keys are provided" do
      ApnClient::NamedArgs.assert_allowed!({:foo => 1, :bar => 2}, [:foo, :bar])
    end

    it "does not raise an exception if a subset of allowed keys are provided" do
      ApnClient::NamedArgs.assert_allowed!({:foo => 1}, [:foo, :bar])
    end
  end

  describe ".assert_present!" do
    it "raises an exception if arguments are empty and required keys are not empty" do
      lambda {
        ApnClient::NamedArgs.assert_present!({}, [:foo])
      }.should raise_error(/foo/)
    end

    it "does not raise an exception if arguments are empty and required keys are empty" do
      ApnClient::NamedArgs.assert_present!({}, [])
    end

    it "raises an exception if arguments have some but not all required keys" do
      lambda {
        ApnClient::NamedArgs.assert_present!({:bar => 1}, [:foo, :bar])
      }.should raise_error(/foo/)
    end

    it "does not raise an excpeption if arguments have all required keys" do
      ApnClient::NamedArgs.assert_present!({:foo => 1, :bar => 2}, [:foo, :bar])
    end
  end

  describe ".assert_valid!" do
    it "can take only optional keys" do
      arguments = {:foo => 1}
      ApnClient::NamedArgs.expects(:assert_allowed!).with(arguments, [:foo])
      ApnClient::NamedArgs.expects(:assert_present!).with(arguments, [])
      ApnClient::NamedArgs.assert_valid!(arguments, :optional => [:foo])
    end

    it "can take only required keys" do
      arguments = {:foo => 1}
      ApnClient::NamedArgs.expects(:assert_allowed!).with(arguments, [:foo])
      ApnClient::NamedArgs.expects(:assert_present!).with(arguments, [:foo])
      ApnClient::NamedArgs.assert_valid!(arguments, :required => [:foo])
    end

    it "can take both optional and required keys" do
      arguments = {:foo => 1}
      ApnClient::NamedArgs.expects(:assert_allowed!).with(arguments, [:bar, :foo])
      ApnClient::NamedArgs.expects(:assert_present!).with(arguments, [:foo])
      ApnClient::NamedArgs.assert_valid!(arguments, :required => [:foo], :optional => [:bar])
    end

    it "does not raise exception if only required args are provided" do
      ApnClient::NamedArgs.assert_valid!({:foo => 1}, :required => [:foo], :optional => [:bar])
    end

    it "does not raise exception if required and optional args are provided" do
      ApnClient::NamedArgs.assert_valid!({:foo => 1, :bar => 2}, :required => [:foo], :optional => [:bar])
    end

    it "raises an exception if a required arg is missing" do
      lambda {
        ApnClient::NamedArgs.assert_valid!({:bar => 2}, :required => [:foo], :optional => [:bar])
      }.should raise_error(/foo/)
    end

    it "raises an exception if an invalid arg is present" do
      lambda {
        ApnClient::NamedArgs.assert_valid!({:foo => 1, :bar => 2, :bla => 3}, :required => [:foo], :optional => [:bar])
      }.should raise_error(/bla/)
    end

    it "does not raise an exception if args are nil and all keys are optional" do
      ApnClient::NamedArgs.assert_valid!(nil, :optional => [:bar])
    end
  end
  
  describe ".symbolize_keys!" do
    it "takes a hash and symbolizes its keys" do
      attributes = {
        'foo' => 1,
        :bar => 2
      }
      ApnClient::NamedArgs.symbolize_keys!(attributes)
      attributes.should == {
        :foo => 1,
        :bar => 2
      }
    end
  end
end
