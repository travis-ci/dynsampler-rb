# OnlyOnce implements Sampler and returns a sample rate of 1 the first time a
# key is seen and 1,000,000,000 every subsequent time.  Essentially, this means
# that every key will be reported the first time it's seen during each
# ClearFrequencySec and never again.  Set ClearFrequencySec to -1 to report
# each key only once for the life of the process.
#
# (Note that it's not guaranteed that each key will be reported exactly once,
# just that the first seen event will be reported and subsequent events are
# unlikely to be reported. It is probable that an additional event will be
# reported for every billion times the key appears.)
#
# This emulates what you might expect from something catching stack traces -
# the first one is important but every subsequent one just repeats the same
# information.

module DynSampler
  class OnlyOnce
    attr_accessor :seen

    def initialize(clear_frequency_sec = 30)
      @clear_frequency_sec = clear_frequency_sec
      @seen = {}
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
        seen = @seen[key]
        @seen[key] = true
        seen ? 1000000000 : 1
      }
    end

    def update_maps
      @lock.synchronize {
        @seen = {}
      }
    end
  end
end
