require 'dynsampler/only_once'

RSpec.describe DynSampler::OnlyOnce do
  it "updates the maps" do
    sampler = DynSampler::OnlyOnce.new

    tests = [
      [
        {
          one:   true,
          two:   true,
          three: true,
        },
        {},
      ],
      [
        {},
        {},
      ],
    ]

    tests.each do |test|
      seen, expected = test

      sampler.seen = seen
      sampler.update_maps
      expect(sampler.seen).to eq(expected)
    end
  end

  it "samples only once" do
    sampler = DynSampler::OnlyOnce.new
    sampler.seen = {
      one: true,
      two: true,
    }

    tests = [
      [:one, 1000000000, true, true],
      [:two, 1000000000, true, true],
      [:two, 1000000000, true, true],
      [:three, 1, nil, true], # key missing from seen
      [:three, 1000000000, true, true],
      [:four, 1, nil, true], # key missing from seen
      [:four, 1000000000, true, true],
    ]

    tests.each do |test|
      key, expected, expected_count_before, expected_count_after = test

      expect(sampler.seen[key]).to eq(expected_count_before)
      rate = sampler.sample_rate(key)
      expect(rate).to eq(expected)
      expect(sampler.seen[key]).to eq(expected_count_after)
    end
  end
end
