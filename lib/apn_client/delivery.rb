module ApnClient
  class Delivery
    attr_accessor :message_queue, :callbacks, :consecutive_failure_limit, :exception_limit, :sleep_on_exception,
      :exception_count, :success_count, :failure_count, :consecutive_failure_count,
      :started_at, :finished_at

    def initialize(messages, options = {})
      initialize_message_queue(messages)
      initialize_options(options)
      self.exception_count = 0
      self.success_count = 0
      self.failure_count = 0
    end

    def process!
      self.started_at = Time.now
      while current_message && consecutive_failure_count < consecutive_failure_limit
        process_one_message!
      end
      close_connection
      self.finished_at = Time.now
    end

    def elapsed
      finished_at ? (finished_at - started_at) : (Time.now - started_at)
    end

    private

    def initialize_message_queue(messages)
      if messages.respond_to?(:next)
        self.message_queue = messages
      else
        self.message_queue = messages.to_enum
      end
    end

    def initialize_options(options)
      check_option_keys_valid!(options)
      check_callback_keys_valid!(options[:callbacks])
      self.callbacks = options[:callbacks]
      self.consecutive_failures_limit = options[:consecutive_failures_limit]
      self.exception_limit = options[:exception_limit]
      self.sleep_on_exception = options[:sleep_on_exception] || 1      
    end
    
    def current_message
      return @current_message if @current_message
      next_message!
    end
    
    def next_message!
      @current_message = message_queue.next
    rescue StopIteration
      nil
    end
    
    def process_one_message!
      begin
        write_message!
        check_message_error!
      rescue Exception => e
        handle_exception!(e)
        check_message_error! unless @checked_message_error
        close_connection
      end
    end

    def connection
      @connection ||= Connection.new(self.class.connection_config)
    end

    def close_connection
      @connection.close if @connection
      @connection = nil
    end

    def write_message!
      @checked_message_error = false
      connection.write(current_message)
      self.exception_count = 0; self.consecutive_failure_count = 0; self.success_count += 1
      invoke_callback(:on_write, current_message)
      next_message!
    end
    
    def check_message_error!
      @checked_message_error = true
      failed_message_id, error_code = read_apns_error
      # NOTE: According to the APN documentation the APN service will return an error code prior to
      # disconnecting. If we don't disconnect here we will attempt to write more messages
      # before a broken pipe error is raised and those messages will never be delivered.
      if failed_message_id
        invoke_callback(:on_error, failed_message_id, error_code)
        self.failure_count += 1
        self.success_count -= 1
        close_connection
      end
    end

    def read_apns_error
      message_id = error_code = nil
      begin
        select_return = nil
        if connection && select_return = connection.select
          response = connection.read(6)
          command, status_code, message_id = response.unpack('cci') if response
        else
          invoke_callback(:on_nil_select)
        end
      rescue Exception => e
        # NOTE: If we don't catch this exception then one socket read exception could break out of the whole delivery loop
        invoke_callback(:on_read_exception, e)
      end
      return message_id, error_code
    end

    def handle_exception!(e)
      self.exception_count += 1
      fail_message! if exception_limit_reached?
      sleep(sleep_on_exception) if sleep_on_exception
    end

    def exception_limit_reached?
      exception_count == exception_limit
    end

    # # Give up on the message and move on to the next one
    def fail_message!
      self.failure_count += 1; self.consecutive_failures += 1; self.exception_count = 0
      invoke_callback(:on_failure, current_message)
      next_message!
    end
    
    def invoke_callback(name, *args)
      callbacks[name].call(self, *args) if callbacks[name]
    end
  end
end