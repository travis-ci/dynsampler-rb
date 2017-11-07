require 'dynsampler/total_throughput'

RSpec.describe DynSampler::TotalThroughput do
  it "updates the maps" do
    sampler = DynSampler::TotalThroughput.new(30, 20)

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
          eight: 10,
          nine:  33,
          ten:   166,
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
          one:   8,
          two:   8,
          three: 16,
          four:  41,
          five:  58,
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
          one:   50,
          two:   50,
          three: 50,
          four:  50,
          five:  50,
        },
      ],
      [
        {
          one: 12000,
        },
        {
          one: 20,
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

  it "samples based on total throughput" do
    sampler = DynSampler::TotalThroughput.new
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
      key, expected, expected_count = test

      rate = sampler.sample_rate(key)
      expect(rate).to eq(expected)
      expect(sampler.current_counts[key]).to eq(expected_count)
    end
  end
end
