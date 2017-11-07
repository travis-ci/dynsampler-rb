require 'dynsampler/per_key_throughput'

RSpec.describe DynSampler::PerKeyThroughput do
  it "updates maps" do
    sampler = DynSampler::PerKeyThroughput.new(
      per_key_throughput_per_sec: 5,
    )

    tests = [
      [
        {
          one:   1,
          two:   1,
          three: 2,
          four:  5,
          five:  8,
          six:   15,
          seven: 45,
          eight: 612,
          nine:  2000,
          ten:   10000,
        },
        {
          one:   1,
          two:   1,
          three: 1,
          four:  1,
          five:  1,
          six:   1,
          seven: 1,
          eight: 4,
          nine:  13,
          ten:   66,
        },
      ],
      [
        {
          one:   1,
          two:   1,
          three: 2,
          four:  5,
          five:  8,
          six:   15,
          seven: 45,
          eight: 50,
          nine:  60,
        },
        {
          one:   1,
          two:   1,
          three: 1,
          four:  1,
          five:  1,
          six:   1,
          seven: 1,
          eight: 1,
          nine:  1,
        },
      ],
      [
        {
          one:   1,
          two:   1,
          three: 2,
          four:  5,
          five:  7,
        },
        {
          one:   1,
          two:   1,
          three: 1,
          four:  1,
          five:  1,
        },
      ],
      [
        {
          one:   1000,
          two:   1000,
          three: 2000,
          four:  5000,
          five:  7000,
        },
        {
          one:   6,
          two:   6,
          three: 13,
          four:  33,
          five:  46,
        },
      ],
      [
        {
          one:   1000,
          two:   1000,
          three: 2000,
          four:  5000,
          five:  70000,
        },
        {
          one:   6,
          two:   6,
          three: 13,
          four:  33,
          five:  466,
        },
      ],
      [
        {
          one:   6000,
          two:   6000,
          three: 6000,
          four:  6000,
          five:  6000,
        },
        {
          one:   40,
          two:   40,
          three: 40,
          four:  40,
          five:  40,
        },
      ],
      [
        {
          one: 12000,
        },
        {
          one: 80,
        },
      ],
      [
        {},
        {},
      ],
    ]

    tests.each do |test|
      counts, expected = test

      sampler.current_counts = counts
      sampler.update_maps
      expect(sampler.current_counts.size).to eq(0)
      expect(sampler.saved_sample_rates).to eq(expected)
    end
  end

  it "samples per key throughput" do
    sampler = DynSampler::PerKeyThroughput.new
    sampler.current_counts = {
      one: 5,
      two: 8,
    }
    sampler.saved_sample_rates = {
      one: 10,
      two: 1,
      three: 5,
    }

    tests = [
      [:one, 10, 6],
      [:two, 1, 9],
      [:two, 1, 10],
      [:three, 5, 1], # key missing from current counts
      [:three, 5, 2],
      [:four, 1, 1], # key missing from current and saved counts
      [:four, 1, 2],
    ]

    tests.each do |test|
      key, expected, expected_counts = test

      rate = sampler.sample_rate(key)
      expect(rate).to eq(expected)
      expect(sampler.current_counts[key]).to eq(expected_counts)
    end
  end
end
