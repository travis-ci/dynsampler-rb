require 'dynsampler/avg_sample_with_min'

RSpec.describe DynSampler::AvgSampleWithMin do
  it "updates maps" do
    sampler = DynSampler::AvgSampleWithMin.new(30, 20)

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
          eight: 6,
          nine:  14,
          ten:   47,
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
          one: 1,
        },
        {
          one: 1,
        },
      ],
      [
        {
          one: 8,
        },
        {
          one: 1,
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
        {
          one:   1000,
          two:   1000,
          three: 2000,
          four:  5000,
          five:  7000,
        },
        {
          one:   7,
          two:   7,
          three: 13,
          four:  29,
          five:  39,
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
          one:   20,
          two:   20,
          three: 20,
          four:  20,
          five:  20,
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

  it "starts up" do
    sampler = DynSampler::AvgSampleWithMin.new(30, 10)

    rate = sampler.sample_rate(:key)
    expect(rate).to eq(10)
    expect(sampler.current_counts[:key]).to eq(1)
  end

  it "samples to avg sample rate" do
    sampler = DynSampler::AvgSampleWithMin.new
    sampler.have_data = true
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
