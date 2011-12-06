module ApnClient
  class Message
    attr_accessor :attributes

    # Creates an APN message to to be sent over SSL to the APN service.
    #
    # @param [Fixnum] message_id a unique (at least within a delivery) integer identifier for this message (required)
    # @param [String] device_token A 64 byte long hex digest supplied from an app installed on a device to the server (required)
    # @param [String] alert A text message to display to the user. Should be tweet sized (payload may not exceed 256 bytes)
    # @param [Fixnum] badge the number to show on the badge on the app icon - number of new/unread items
    # @param [String] sound filename of a sound file in the app bundle to be played to the user
    # @param [Boolean] content_available set to true if the message should trigger download of new content
    def initialize(attributes = {})
      self.attributes = NamedArgs.symbolize_keys!(attributes)
      NamedArgs.assert_valid!(attributes,
        :optional => self.class.optional_attributes,
        :required => self.class.required_attributes)
      check_payload_size!
    end

    # We use the enhanced format. See the Apple documentation for details.
    def to_s
      [1, message_id, self.class.expires_at, 0, 32, device_token, 0, payload_size, payload].pack('ciiccH*cca*')
    end

    def ==(other_message)
      other_message && other_message.is_a?(self.class) && other_message.message_id == self.message_id
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

    # Delegate attribute reading and writing (#attribute_name and #attribute_name=)
    # to the attributes hash.
    def method_missing(method_name, *args)
      method_match, attribute_name, equal_sign = method_name.to_s.match(/\A([^=]+)(=)?\Z/).to_a
      if attribute_name && self.class.valid_attributes.include?(attribute_name.to_sym)
        if equal_sign          
          attributes[attribute_name.to_sym] = args.first
        else
          attributes[attribute_name.to_sym]
        end
      else
        super
      end
    end

    def self.optional_attributes
      [:alert, :badge, :sound, :content_available]
    end

    def self.required_attributes
      [:message_id, :device_token]
    end

    def self.valid_attributes
      optional_attributes + required_attributes
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

    def to_hash
      attributes
    end

    def to_json
      to_hash.to_json
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
