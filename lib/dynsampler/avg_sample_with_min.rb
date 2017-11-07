# AvgSampleWithMin implements Sampler and attempts to average a given sample
# rate, with a minimum number of events per second (i.e. it will reduce
# sampling if it would end up sending fewer than the mininum number of events).
# This method attempts to get the best of the normal average sample rate
# method, without the failings it shows on the low end of total traffic
# throughput
#
# Keys that occur only once within ClearFrequencySec will always have a sample
# rate of 1. Keys that occur more frequently will be sampled on a logarithmic
# curve. In other words, every key will be represented at least once per
# ClearFrequencySec and more frequent keys will have their sample rate
# increased proportionally to wind up with the goal sample rate.

module DynSampler
  class AvgSampleWithMin
    attr_accessor :saved_sample_rates, :current_counts, :have_data

    def initialize(options = {})
      @clear_frequency_sec = options.delete(:clear_frequency_sec) || 30
      @goal_sample_rate = options.delete(:goal_sample_rate) || 10
      @min_events_per_sec = options.delete(:min_events_per_sec) || 50

      @saved_sample_rates = {}
      @current_counts = {}

      @have_data = false
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

        if @have_data
          @saved_sample_rates[key] || 1
        else
          @goal_sample_rate
        end
      }
    end

    def update_maps
      tmp_counts = nil
      @lock.synchronize {
        tmp_counts = @current_counts
        @current_counts = {}
      }

      new_saved_sample_rates = {}

      num_keys = tmp_counts.size
      if num_keys == 0
        @lock.synchronize {
          @saved_sample_rates = {}
        }
        return
      end

      sum_events = tmp_counts.values.reduce(0, :+)
      goal_count = sum_events.to_f/@goal_sample_rate.to_f

      if sum_events < @min_events_per_sec * @clear_frequency_sec
        new_saved_sample_rates = tmp_counts.keys.map {|k| [k, 1]}.to_h
        @lock.synchronize {
          @saved_sample_rates = new_saved_sample_rates
        }
        return
      end

      log_sum = tmp_counts.values.map {|v| Math.log10(v.to_f)}.reduce(0.0, :+)
      goal_ratio = goal_count/log_sum

      keys = tmp_counts.keys.sort

      keys_remaining = keys.size
      extra = 0.0
      keys.each do |key|
        count = tmp_counts[key].to_f
        goal_for_key = [1, Math.log10(count)*goal_ratio].max

        extra_for_key = extra / keys_remaining.to_f
        goal_for_key += extra_for_key

        extra -= extra_for_key
        keys_remaining -= 1

        if count <= goal_for_key
          new_saved_sample_rates[key] = 1
          extra += goal_for_key - count
        else
          new_saved_sample_rates[key] = (count / goal_for_key).ceil.to_i
          extra += goal_for_key - (count / new_saved_sample_rates[key].to_f)
        end
      end

      @lock.synchronize {
        @saved_sample_rates = new_saved_sample_rates
        @have_data = true
      }
    end
  end
end
