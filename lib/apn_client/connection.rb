require 'socket'
require 'openssl'
require 'apn_client/named_args'

module ApnClient
  class Connection
    attr_accessor :config, :tcp_socket, :ssl_socket

    # Opens an SSL socket for talking to the Apple Push Notification service.
    #
    # @param [String] host the hostname to connect to
    # @param [Fixnum] port the port to connect to
    # @param [String] certificate the APN certificate to use
    # @param [String] certificate_passphrase the passphrase of the certificate, can be empty
    # @param [Float] select_timeout the timeout (seconds) used when doing IO.select on the socket (default 0.1)
    def initialize(config = {})
      NamedArgs.assert_valid!(config,
        :required => [:host, :port, :certificate, :certificate_passphrase],
        :optional => [:select_timeout])
      self.config = config
      config[:select_timeout] ||= 0.1
      connect_to_socket
    end

    def close
      ssl_socket.close
      tcp_socket.close
      self.ssl_socket = nil
      self.tcp_socket = nil
    end

     def write(arg)
       ssl_socket.write(arg.to_s)
     end

     def read(*args)
       ssl_socket.read(*args)
     end

     def select
       IO.select([ssl_socket], nil, nil, config[:select_timeout])
     end

     def self.open(options = {})
       connection = Connection.new(options)
       yield connection
     ensure
       connection.close if connection
     end

    private

    def connect_to_socket
      context = OpenSSL::SSL::SSLContext.new
      context.key = OpenSSL::PKey::RSA.new(config[:certificate], config[:certificate_passphrase])
      context.cert = OpenSSL::X509::Certificate.new(config[:certificate])

      self.tcp_socket = TCPSocket.new(config[:host], config[:port])
      self.ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, context)
      ssl_socket.sync = true
      ssl_socket.connect
    end
  end
end
