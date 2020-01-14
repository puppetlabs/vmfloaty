# frozen_string_literal: true

# All of the interfaces for the different services must be the
# same, otherwise there will be errors when you change the caller
# for the services from services.rb.
#

require_relative '../../lib/vmfloaty/pooler'
require_relative '../../lib/vmfloaty/abs'
require_relative '../../lib/vmfloaty/nonstandard_pooler'

shared_examples 'a vmfloaty service' do
  it { is_expected.to respond_to(:delete).with(5).arguments }
  it { is_expected.to respond_to(:disk).with(5).arguments }
  it { is_expected.to respond_to(:list).with(3).arguments }
  it { is_expected.to respond_to(:list_active).with(4).arguments }
  it { is_expected.to respond_to(:modify).with(5).arguments }
  it { is_expected.to respond_to(:retrieve).with(6).arguments }
  it { is_expected.to respond_to(:revert).with(5).arguments }
  it { is_expected.to respond_to(:query).with(3).arguments }
  it { is_expected.to respond_to(:snapshot).with(4).arguments }
  it { is_expected.to respond_to(:status).with(2).arguments }
  it { is_expected.to respond_to(:summary).with(2).arguments }
end

describe Pooler do
  subject { Pooler }
  it_behaves_like 'a vmfloaty service'
end

describe ABS do
  subject { ABS }
  it_behaves_like 'a vmfloaty service'
end

describe NonstandardPooler do
  subject { NonstandardPooler }
  it_behaves_like 'a vmfloaty service'
end
