module DynSampler
  class Static
    def initialize(rates, default = 1)
      @rates = rates
      @default = default
    end

    def start
    end

    def sample_rate(key)
      @rates[key] || @default
    end
  end
end
