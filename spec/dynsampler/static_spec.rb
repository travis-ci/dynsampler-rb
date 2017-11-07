require 'dynsampler/static'

RSpec.describe DynSampler::Static do
  it "samples at a static rate" do
    sampler = DynSampler::Static.new({
      one: 5,
      two: 10,
    }, 3)

    expect(sampler.sample_rate(:one)).to eq(5)
    expect(sampler.sample_rate(:two)).to eq(10)
    expect(sampler.sample_rate(:three)).to eq(3)
  end
end
