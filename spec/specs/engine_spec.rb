require 'spec_helper'
require 'metricks/engine'

describe Metricks::Engine do

  let(:mock_app) do
    Class.new(Rails::Application) do
      config.eager_load = false
    end
  end

  before do
    allow(Metricks::Lock).to receive(:validate!).and_call_original
  end

  it 'allows with_lock to be configured' do
    success = false

    allow(mock_app.config.metricks).to receive(:with_lock)
      .and_return(->(result, opts, block) { block.call(result, opts) })

    expect {
      mock_app.initialize!
    }.not_to raise_error

    Metricks::Lock.with_lock(true, {}) do |result|
      success = result
    end

    expect(success).to be(true)

    expect(Metricks::Lock).to have_received(:validate!)
  end

end
