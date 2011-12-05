require 'spec_helper'

describe ApnClient::Delivery do
  before(:each) do
    @message1 = ApnClient::Message.new(1,
      :device_token => "7b7b8de5888bb742ba744a2a5c8e52c6481d1deeecc283e830533b7c6bf1d099",
      :alert => "New version of the app is out. Get it now in the app store!",
      :badge => 2
    )
    @message2 = ApnClient::Message.new(2,
      :device_token => "6a5g4de5888bb742ba744a2a5c8e52c6481d1deeecc283e830533b7c6bf1d044",
      :alert => "New version of the app is out. Get it now in the app store!",
      :badge => 1
    )
  end

  describe "#initialize" do
    it "initializes counts and other attributes" do
      delivery = create_delivery([@message1, @message2], :connection => {})
    end
  end

  describe "#process!" do
    it "can deliver to all messages successfully and invoke on_write callback" do
      messages = [@message1, @message2]
      written_messages = []
      nil_selects = 0
      callbacks = {
          :on_write => lambda { |d, m| written_messages << m },
          :on_nil_select => lambda { |d| nil_selects += 1 }
        }
      delivery = create_delivery(messages.dup, :callbacks => callbacks, :connection => {})

      connection = mock('connection')
      connection.expects(:write).with(@message1)
      connection.expects(:write).with(@message2)
      connection.expects(:select).times(2).returns(nil)
      delivery.stubs(:connection).returns(connection)

      delivery.process!

      delivery.failure_count.should == 0
      delivery.success_count.should == 2
      delivery.total_count.should == 2
      written_messages.should == messages
      nil_selects.should == 2
    end

    it "fails a message if it fails more than 3 times" do
      messages = [@message1, @message2]
      written_messages = []
      exceptions = []
      failures = []
      read_exceptions = []
      callbacks = {
          :on_write => lambda { |d, m| written_messages << m },
          :on_exception => lambda { |d, e| exceptions << e },
          :on_failure => lambda { |d, m| failures << m },
          :on_read_exception => lambda { |d, e| read_exceptions << e }
        }
      delivery = create_delivery(messages.dup, :callbacks => callbacks, :connection => {})

      connection = mock('connection')
      connection.expects(:write).with(@message1).times(3).raises(RuntimeError)
      connection.expects(:write).with(@message2)
      connection.expects(:select).times(4).raises(RuntimeError)
      delivery.stubs(:connection).returns(connection)

      delivery.process!

      delivery.failure_count.should == 1
      delivery.success_count.should == 1
      delivery.total_count.should == 2
      written_messages.should == [@message2]
      exceptions.size.should == 3
      exceptions.first.is_a?(RuntimeError).should be_true
      failures.should == [@message1]
      read_exceptions.size.should == 4
    end

    it "invokes on_error callback if there are errors read" do
      messages = [@message1, @message2]
      written_messages = []
      exceptions = []
      failures = []
      read_exceptions = []
      errors = []
      callbacks = {
          :on_write => lambda { |d, m| written_messages << m },
          :on_exception => lambda { |d, e| exceptions << e },
          :on_failure => lambda { |d, m| failures << m },
          :on_read_exception => lambda { |d, e| read_exceptions << e },
          :on_error => lambda { |d, message_id, error_code| errors << [message_id, error_code] }
        }
      delivery = create_delivery(messages.dup, :callbacks => callbacks, :connection => {})

      connection = mock('connection')
      connection.expects(:write).with(@message1)
      connection.expects(:write).with(@message2)
      selects = sequence('selects')
      connection.expects(:select).returns("something").in_sequence(selects)
      connection.expects(:select).returns(nil).in_sequence(selects)
      connection.expects(:read).returns("something")
      delivery.stubs(:connection).returns(connection)

      delivery.process!

      delivery.failure_count.should == 1
      delivery.success_count.should == 1
      delivery.total_count.should == 2
      written_messages.should == [@message1, @message2]
      exceptions.size.should == 0
      failures.size.should == 0
      errors.should == [[1752458605, 111]]
    end
  end

  def create_delivery(messages, options = {})
    delivery = ApnClient::Delivery.new(messages, options)
    delivery.messages.should == messages
    delivery.callbacks.should == options[:callbacks]
    delivery.exception_count.should == 0
    delivery.success_count.should == 0
    delivery.failure_count.should == 0
    delivery.consecutive_failure_count.should == 0
    delivery.started_at.should be_nil
    delivery.finished_at.should be_nil
    delivery.elapsed.should == 0
    delivery.consecutive_failure_limit.should == 10
    delivery.exception_limit.should == 3
    delivery.sleep_on_exception.should == 1
    delivery
  end
end
