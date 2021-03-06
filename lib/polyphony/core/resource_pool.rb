# frozen_string_literal: true

module Polyphony
  # Implements a limited resource pool
  class ResourcePool
    attr_reader :limit, :size

    # Initializes a new resource pool
    # @param opts [Hash] options
    # @param &block [Proc] allocator block
    def initialize(opts, &block)
      @allocator = block

      @stock = []
      @queue = []
      @acquired_resources = {}

      @limit = opts[:limit] || 4
      @size = 0
    end

    def available
      @stock.size
    end

    def acquire
      fiber = Fiber.current
      if @acquired_resources[fiber]
        yield @acquired_resources[fiber]
      else
        begin
          Thread.current.agent.ref
          resource = wait_for_resource
          return unless resource
          
          @acquired_resources[fiber] = resource
          yield resource
        ensure
          @acquired_resources[fiber] = nil
          Thread.current.agent.unref
          release(resource) if resource
        end
      end
    end
        
    def wait_for_resource
      fiber = Fiber.current
      @queue << fiber
      ready_resource = from_stock
      return ready_resource if ready_resource

      suspend
    ensure
      @queue.delete(fiber)
    end

    def release(resource)
      if resource.__discarded__
        @size -= 1
      elsif resource
        return_to_stock(resource)
        dequeue
      end
    end

    def dequeue
      return if @queue.empty? || @stock.empty?

      @queue.shift.schedule(@stock.shift)
    end

    def return_to_stock(resource)
      @stock << resource
    end

    def from_stock
      @stock.shift || (@size < @limit && allocate)
    end

    def method_missing(sym, *args, &block)
      acquire { |r| r.send(sym, *args, &block) }
    end

    def respond_to_missing?(*_args)
      true
    end

    # Extension to allow discarding of resources
    module ResourceExtensions
      def __discarded__
        @__discarded__
      end

      def __discard__
        @__discarded__ = true
      end
    end

    # Allocates a resource
    # @return [any] allocated resource
    def allocate
      @size += 1
      @allocator.().tap { |r| r.extend ResourceExtensions }
    end

    def <<(resource)
      @size += 1
      resource.extend ResourceExtensions
      @stock << resource
      dequeue
    end

    def preheat!
      (@limit - @size).times { @stock << allocate }
    end
  end
end
