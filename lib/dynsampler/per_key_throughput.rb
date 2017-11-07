# PerKeyThroughput implements Sampler and attempts to meet a goal of a fixed
# number of events per key per second sent to Honeycomb.
#
# This method is to guarantee that at most a certain number of events per key
# get transmitted, no matter how many keys you have or how much traffic comes
# through. In other words, if capturing a minimum amount of traffic per key is
# important but beyond that doesn't matter much, this is the best method.

module DynSampler
  class PerKeyThroughput
    attr_accessor :saved_sample_rates, :current_counts

    def initialize(clear_frequency_sec = 30, per_key_throughput_per_sec = 10)
      @clear_frequency_sec = clear_frequency_sec
      @per_key_throughput_per_sec = per_key_throughput_per_sec

      @saved_sample_rates = {}
      @current_counts = {}

      @lock = Mutex.new
    end

    def start
      Thread.new {
        loop do
          sleep @clear_frequency_sec
          update_maps
        end
      }
    end

    def sample_rate(key)
      @lock.synchronize {
        @current_counts[key] ||= 0
        @current_counts[key] += 1

        @saved_sample_rates[key] || 1
      }
    end

    def update_maps
      tmp_counts = nil
      @lock.synchronize {
        tmp_counts = @current_counts
        @current_counts = {}
      }

      num_keys = tmp_counts.size
      if num_keys == 0
        @lock.synchronize {
          @saved_sample_rates = {}
        }
        return
      end

      actual_per_key_rate = @per_key_throughput_per_sec * @clear_frequency_sec

      new_saved_sample_rates = {}
      tmp_counts.each do |k,v|
        rate = [1, v.to_f/actual_per_key_rate.to_f].max.to_i
        new_saved_sample_rates[k] = rate
      end

      @lock.synchronize {
        @saved_sample_rates = new_saved_sample_rates
      }
    end
  end
end
