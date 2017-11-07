# AvgSampleRate implements Sampler and attempts to average a given sample rate,
# weighting rare traffic and frequent traffic differently so as to end up with
# the correct average. This method breaks down when total traffic is low
# because it will be excessively sampled.
#
# Keys that occur only once within ClearFrequencySec will always have a sample
# rate of 1. Keys that occur more frequently will be sampled on a logarithmic
# curve. In other words, every key will be represented at least once per
# ClearFrequencySec and more frequent keys will have their sample rate
# increased proportionally to wind up with the goal sample rate.

module DynSampler
  class AvgSampleRate
    attr_accessor :saved_sample_rates, :current_counts, :have_data

    def initialize(options = {})
      @clear_frequency_sec = options.delete(:clear_frequency_sec) || 30
      @goal_sample_rate = options.delete(:goal_sample_rate) || 10

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

      num_keys = tmp_counts.size
      if num_keys == 0
        @lock.synchronize {
          @saved_sample_rates = {}
        }
        return
      end

      sum_events = 0
      tmp_counts.each do |k,v|
        sum_events += v
      end
      goal_count = sum_events.to_f/@goal_sample_rate.to_f

      log_sum = 0.0
      tmp_counts.each do |k,v|
        log_sum += Math.log10(v.to_f)
      end
      goal_ratio = goal_count/log_sum

      keys = tmp_counts.keys.sort

      new_saved_sample_rates = {}
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
