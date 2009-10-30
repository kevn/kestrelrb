require 'memcache'
module Kestrel

  class Queue

    class Unsubscribe < StandardError; end

    SLEEP_DELAY = 0.001 # Seconds to sleep when no messages in queue and GET timeout is 0

    attr_reader :queue_name, :options

    def initialize(queue_name, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      @options = validate_queue_options(opts)
      @queue_name = queue_name
      servers = args.empty? ? ['localhost:22133'] : args
      # Instantiate Memcache client with the specified servers and a timeout of 2x the GET timeout
      @kestrel = MemCache.new(servers, :timeout => timeout * 2)
    end

    def drop
      @kestrel.delete(queue_name)
    end
    
    def flush
      raise NotImplementedError, "FLUSH command is not yet supported."
      # @kestrel.flush
    end

    def flush_all
      @kestrel.flush_all
    end

    def stats
      @kestrel.stats
    end

    def on_error(&block)
      (@error_handlers ||= []) << block
    end

    def subscribe(&block)
      loop do
        msg = nil
        begin
          if msg = get
            block.call(msg)
          else
            sleep SLEEP_DELAY if timeout == 0
          end
        rescue Unsubscribe => e
          break
        rescue StandardError => e
          abort if reliable?
          @error_handlers.each{ |b| b.call(e, msg) } if @error_handlers
        end
      end
    end

    def enqueue(v)
      @kestrel.set(queue_name, v)
    end

    def dequeue(raw = false)
      @kestrel.get(get_key, raw)
    end
    alias get dequeue

    def peek(raw = false)
      @kestrel.get(peek_key, raw)
    end

    def abort
      @kestrel.get(abort_key)
    end

    def timeout
      options[:timeout]
    end

    def reliable?
      options[:reliable]
    end

  protected
    def get_key
      @get_key ||= reliable? ? close_open_key : plain_key
    end

    def plain_key
      @plain_key ||= "#{queue_name}/t=#{timeout}"
    end

    def peek_key
      @peek_key ||= "#{queue_name}/peek"
    end

    def close_open_key
      @close_open_key ||= "#{queue_name}/close/open/t=#{timeout}"
    end

    def open_key
      @open_key ||= "#{queue_name}/open/t=#{timeout}"
    end

    def close_key
      @close_key ||= close_key = "#{queue_name}/close"
    end

    def abort_key
      @abort_key ||= abort_key = "#{queue_name}/abort"
    end

    def validate_queue_options(opts)
      options = default_options.merge(opts)
      unknown_keys = (options.keys - valid_keys)
      raise "Unknown queue options: #{unknown_keys.inspect}" unless unknown_keys.empty?
      options
    end

    def valid_keys
      [:reliable, :timeout]
    end

    def default_options
      {
        :reliable => true,
        :timeout  => 500, #ms
      }
    end

  end

end
