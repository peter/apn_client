module ApnClient
  class NamedArgs
    def self.assert_valid!(arguments, options)
      arguments ||= {}
      options[:optional] ||= []
      options[:required] ||= []
      assert_allowed!(arguments, options[:optional] + options[:required])
      assert_present!(arguments, options[:required])
    end

    def self.assert_allowed!(arguments, allowed_keys)
      invalid_keys = arguments.keys.select { |key| !allowed_keys.include?(key) }
      unless invalid_keys.empty?
        raise "Invalid arguments: #{invalid_keys.join(', ')}. Must be one of #{allowed_keys.join(', ')}"
      end
    end

    def self.assert_present!(arguments, required_keys)
      missing_keys = required_keys.select { |key| !arguments.keys.include?(key) }
      unless missing_keys.empty?
        raise "Missing required arguments: #{missing_keys.join(', ')}"
      end
    end

    # Destructively convert all keys to symbols, as long as they respond
    # to +to_sym+.
    def self.symbolize_keys!(arguments)
      arguments.keys.each do |key|
        arguments[(key.to_sym rescue key) || key] = arguments.delete(key)
      end
      arguments
    end
  end
end
