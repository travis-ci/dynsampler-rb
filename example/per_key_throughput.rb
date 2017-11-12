$: << 'lib'
require 'dynsampler'

sampler = DynSampler::PerKeyThroughput.new(
  clear_frequency_sec: 2,
  per_key_throughput_per_sec: 1,
)
sampler.start

prev = {}
(0..20000).each do |i|
  [:foo, :bar].each do |key|
    rate = sampler.sample_rate(key)
    if rate != prev[key]
      puts "#{key}: #{rate}"
      prev[key] = rate
    end
    sleep 0.001
  end
end
