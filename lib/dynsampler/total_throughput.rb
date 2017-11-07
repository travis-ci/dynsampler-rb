# TotalThroughput implements Sampler and attempts to meet a goal of a fixed
# number of events per second sent to Honeycomb.
#
# If your key space is sharded across different servers, this is a good method
# for making sure each server sends roughly the same volume of content to
# Honeycomb. It performs poorly when active the keyspace is very large.
#
# GoalThroughputSec * ClearFrequencySec defines the upper limit of the number
# of keys that can be reported and stay under the goal, but with that many
# keys, you'll only get one event per key per ClearFrequencySec, which is very
# coarse. You should aim for at least 1 event per key per sec to 1 event per
# key per 10sec to get reasonable data. In other words, the number of active
# keys should be less than 10*GoalThroughputSec.

module DynSampler
  class TotalThroughput
    attr_accessor :current_counts, :saved_sample_rates

    def initialize(options = {})
      @clear_frequency_sec = options.delete(:clear_frequency_sec) || 30
      @goal_throughput_per_sec = options.delete(:goal_throughput_per_sec) || 100

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

      total_goal_throughput = @goal_throughput_per_sec * @clear_frequency_sec
      throughput_per_key = [1, total_goal_throughput.to_f/num_keys.to_f].max.to_i

      new_saved_sample_rates = {}
      tmp_counts.each do |k,v|
        rate = [1, v.to_f/throughput_per_key.to_f].max.to_i
        new_saved_sample_rates[k] = rate
      end

      @lock.synchronize {
        @saved_sample_rates = new_saved_sample_rates
      }
    end
  end
end
