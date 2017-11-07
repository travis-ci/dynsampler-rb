module DynSampler
  class Static
    def initialize(options = {})
      @rates = options.delete(:rates)
      @default = options.delete(:default) || 1

      unless @rates
        raise ArgumentError.new(':rates option was not provided')
      end
    end

    def start
    end

    def sample_rate(key)
      @rates[key] || @default
    end
  end
end
