require 'spec_helper'

describe ApnClient::Connection do
  describe "#initialize" do
    it "opens an SSL connection given host, port, certificate, and certificate_passphrase" do
      if certificate_exists?
        connection = ApnClient::Connection.new(valid_config)
        connection.config.should == valid_config_with_defaults
        connection.tcp_socket.is_a?(TCPSocket).should be_true
        connection.ssl_socket.is_a?(OpenSSL::SSL::SSLSocket).should be_true
      end
    end

    it "raises an exception if a required argument is missing" do
      if certificate_exists?
        TCPSocket.expects(:new).never
        lambda {
          connection = ApnClient::Connection.new(valid_config.reject { |key| key == :host })
        }.should raise_error(/host/)
      end
    end

    it "can take a select_timeout argument" do
      if certificate_exists?
        config = valid_config.merge(:select_timeout => 0.5)
        connection = ApnClient::Connection.new(config)
        connection.config.should == config
        connection.tcp_socket.is_a?(TCPSocket).should be_true
        connection.ssl_socket.is_a?(OpenSSL::SSL::SSLSocket).should be_true
      end
    end

    it "does not accept invalid arguments" do
      invalid_config = valid_config.merge({:foobar => 1})
      TCPSocket.expects(:new).never
      lambda {
        ApnClient::Connection.new(invalid_config)
      }.should raise_error(/foobar/)
    end
  end

  describe "#close" do
    it "closes ssl and tcp sockets and sets them to nil" do
      if certificate_exists?
        connection = ApnClient::Connection.new(valid_config)
        connection.close
        connection.tcp_socket.should be_nil
        connection.ssl_socket.should be_nil
      end
    end
  end

  describe "#write" do
    it "invokes write on the ssl socket" do
      ApnClient::Connection.any_instance.expects(:connect_to_socket)
      connection = ApnClient::Connection.new(valid_config)
      ssl_socket = mock('ssl_socket')
      ssl_socket.expects(:write).with('foo')
      connection.expects(:ssl_socket).returns(ssl_socket)
      connection.write(:foo)
    end
  end

  describe "#read" do
    it "invokes read on the ssl socket" do
      ApnClient::Connection.any_instance.expects(:connect_to_socket)
      connection = ApnClient::Connection.new(valid_config)
      ssl_socket = mock('ssl_socket')
      ssl_socket.expects(:read).with("foo", "bar")
      connection.expects(:ssl_socket).returns(ssl_socket)
      connection.read("foo", "bar")
    end
  end

  describe "#select" do
    it "does an IO.select on the ssl socket with a timeout" do
      ApnClient::Connection.any_instance.expects(:connect_to_socket)
      connection = ApnClient::Connection.new(valid_config.merge(:select_timeout => 0.9))
      ssl_socket = mock('ssl_socket')
      connection.expects(:ssl_socket).returns(ssl_socket)
      IO.expects(:select).with([ssl_socket], nil, nil, 0.9)
      connection.select
    end
  end

  describe ".open" do
    it "opens a connection, yields it to a block, then closes it" do
      ApnClient::Connection.any_instance.expects(:connect_to_socket)
      ApnClient::Connection.any_instance.expects(:close)
      ApnClient::Connection.open(valid_config) do |connection|
        connection.config.should == valid_config_with_defaults
      end
    end
  end

  def certificate_path
    File.join(File.dirname(__FILE__), "certificate.pem")
  end

  def certificate_exists?
    File.exists?(certificate_path)
  end

  def valid_config
    {
        :host => 'gateway.push.apple.com',
        :port => 2195,
        :certificate => IO.read(certificate_path),
        :certificate_passphrase => ''
    }
  end

  def valid_config_with_defaults
    valid_config.merge(:select_timeout => 0.1)
  end
end
