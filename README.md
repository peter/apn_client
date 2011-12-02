# APN Client RubyGem

## Introduction

This is a RubyGem that allows sending of Apple Push Notifications to iOS devices (i.e. iPhones, iPads) from Ruby. The main features are:

* Broadcasting of notifications to a large number of devices in a reliable fashion
* Dealing with errors (via the enhanced format Apple protocol) when sending notifications
* Reading from the Apple Feedback Service to avoid sending to devices with uninstalled applications

## Usage

### 1. Configure the Connection

```

ApnClient::Delivery.connection_config = {
  :host => 'gateway.push.apple.com', # For sandbox, use: gateway.sandbox.push.apple.com
  :port => 2195,
  :certificate => IO.read("my_apn_certificate.pem"),
  :certificate_passphrase => '',
}

ApnClient::Feedback.connection_config = {
  :host => 'feedback.push.apple.com', # For sandbox, use: feedback.sandbox.push.apple.com
  :port => 2196,
  :certificate => IO.read("my_apn_certificate.pem"),
  :certificate_passphrase => '',
}

```

### 2. Deliver Your Message

```
message1 = ApnClient::Message.new(1,
  :device_token => "7b7b8de5888bb742ba744a2a5c8e52c6481d1deeecc283e830533b7c6bf1d099",
  :alert => "New version of the app is out. Get it now in the app store!",
  :badge => 2
)
message2 = ApnClient::Message.new(2,
  :device_token => "6a5g4de5888bb742ba744a2a5c8e52c6481d1deeecc283e830533b7c6bf1d044",
  :alert => "New version of the app is out. Get it now in the app store!",
  :badge => 1
)
delivery = ApnClient::Delivery.new([message1, message2],
  :callbacks => {
    :on_write => lambda { |d, m| puts "Wrote message #{m}" },
    :on_exception => lambda { |d, m, e| puts "Exception #{e} raised when delivering message #{m}" },
    :on_failure => lambda { |d, m| puts "Skipping failed message #{m}" },
    :on_error => lambda { |d, message_id, error_code| puts "Received error code #{error_code} from Apple for message #{message_id}" }
  },
  :consecutive_failure_limit => 10, # If more than 10 devices in a row fail, we abort the whole delivery
  :exception_limit => 3 # If a device raises an exception three times in a row we fail/skip the device and move on
)
delivery.process!
puts "Delivered successfully to #{delivery.success_count} out of #{delivery.total_count} devices in #{delivery.elapsed} seconds"
```

One potential gotcha to watch out for is that the device token for a message is per device and per application. This means
that different apps on the same device will have different tokens. The Apple documentation uses phone numbers as an analogy
to explain what a device token is.

### 3. Check for Feedback

TODO

## Dependencies

The payload of an APN message is a JSON formated hash (containing alert message, badge count, content available etc.) and therefore a JSON library needs to be present. This gem requires a Hash#to_json method to be defined (hashes need to respond
to to_json and return valid JSON). If you for example have the json gem or the rails gem in your environment then this requirement is fulfilled.

The gem is tested on MRI 1.9.2.

## Credits

This gem is an extraction of production code at [Mag+](http://www.magplus.com) and both [Dennis Rogenius](https://github.com/denro) and [Lennart Friden](https://github.com/DevL) made important contributions along the way.

The APN connection code has its origins in the [APN on Rails](https://github.com/jwang/apn_on_rails) gem.

## License

This library is released under the MIT license.

## Resources

* [Apple Push Notifications Documentation](http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008194-CH1-SW1)
* [The APNS RubyGem](https://github.com/jpoz/APNS). Has a small codebase and a nice API. Does not use the enhanced format protocol and lacks error handling.
