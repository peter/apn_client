module ApnClient
  class Connection
    def self.valid_config_keys
      [:host, :port, :certificate, :certificate_passphrase]
    end
  end
end
