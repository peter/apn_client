require 'apn_client/named_args'

module ApnClient
  class Message
    attr_accessor :message_id, :device_token, :alert, :badge, :sound, :content_available, :custom_properties

    # Creates an APN message to to be sent over SSL to the APN service.
    #
    # @param [Fixnum] message_id a unique (at least within a delivery) integer identifier for this message
    # @param [String] device_token A 64 byte long hex digest supplied from an app installed on a device to the server
    # @param [String] alert A text message to display to the user. Should be tweet sized (payload may not exceed 256 bytes)
    # @param [Fixnum] badge the number to show on the badge on the app icon - number of new/unread items
    # @param [String] sound filename of a sound file in the app bundle to be played to the user
    # @param [Boolean] content_available set to true if the message should trigger download of new content
    def initialize(message_id, config = {})
      self.message_id = message_id
      self.device_token = device_token
      NamedArgs.assert_valid!(config,
        :optional => [:alert, :badge, :sound, :content_available],
        :required => [:device_token])
      config.keys.each do |key|
        send("#{key}=", config[key])
      end
      check_payload_size!
    end

    # We use the enhanced format. See the Apple documentation for details.
    def to_s
      [1, message_id, self.class.expires_at, 0, 32, device_token, 0, payload_size, payload].pack('ciiccH*cca*')
    end

    def self.error_codes
      {
          :no_errors_encountered => 0,
          :processing_error => 1,
          :missing_device_token => 2,
          :missing_topic => 3,
          :missing_payload => 4,
          :invalid_token_size => 5,
          :invalid_topic_size => 6,
          :invalid_payload_size => 7,
          :invalid_token => 8,
          :unknown => 255
      }
    end

    def self.expires_at
      seconds_per_day = 24*3600
      (Time.now + 30*seconds_per_day).to_i
    end

    # The payload is a JSON formated hash with alert, sound, badge, content-available,
    # and any custom properties, example:
    # {"aps" => {"badge" => 5, "sound" => "my_sound.aiff", "alert" => "Hello!"}}
    def payload
      payload_hash.to_json
    end

    def payload_hash
      result = {}
      result['aps'] = {}
      result['aps']['alert'] = alert if alert
      result['aps']['badge'] = badge if badge and badge > 0
      if sound
        result['aps']['sound'] = sound if sound.is_a? String
        result['aps']['sound'] = "1.aiff" if sound.is_a? TrueClass
      end
      result['aps']['content-available'] = 1 if content_available
      result
    end

    def payload_size
      payload.bytesize
    end

    private

    def check_payload_size!
      max_payload_size = 256
      if payload_size > max_payload_size
        raise "Payload is #{payload_size} bytes and it cannot exceed #{max_payload_size} bytes"
      end
    end
  end
end
