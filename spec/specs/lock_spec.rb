require 'spec_helper'
require 'with_advisory_lock'
require 'metricks/lock'

describe Metricks::Lock do

  describe ".with_lock" do
    before do
      allow(ActiveRecord::Base).to receive(:with_advisory_lock).and_call_original
    end

    context "when with_lock is set" do
      before do
        Metricks::Lock.with_lock = ->(key, opts, block) { block.call(key, opts) }
      end

      it "calls the block with the args" do
        success = false
        passed_opts = {}

        Metricks::Lock.with_lock(true, {hi: 'there'}) do |result, opts|
          success = result
          passed_opts = opts
        end

        expect(success).to be(true)
        expect(passed_opts).to eq({hi: 'there'})
        expect(ActiveRecord::Base).not_to have_received(:with_advisory_lock)
      end
    end

    context "when with_lock is not set" do
      before do
        Metricks::Lock.with_lock = nil
      end

      it "uses with_advisory_lock" do
        success = false

        Metricks::Lock.with_lock(true, timeout_seconds: 5) do |result, opts|
          success = true
        end

        expect(success).to be(true)
        expect(ActiveRecord::Base).to have_received(:with_advisory_lock)
          .with(true, {timeout_seconds: 5})
      end
    end
  end

  describe ".validate!" do
    context "when with_lock is set" do
      before do
        Metricks::Lock.with_lock = ->(key, opts, block) { block.call }
        hide_const("WithAdvisoryLock")
      end

      it "does not raise an error" do
        expect { Metricks::Lock.validate! }.not_to raise_error
      end
    end

    context "when with_lock is not set and WithAdvisoryLock is defined" do
      before do
        stub_const("WithAdvisoryLock", true)
      end

      it "does not raise an error" do
        expect { Metricks::Lock.validate! }.not_to raise_error
      end
    end

    context "when with_lock is not set and WithAdvisoryLock is not defined" do
      before do
        Metricks::Lock.with_lock = nil
        hide_const("WithAdvisoryLock")
      end

      it "raises an error" do
        expect { Metricks::Lock.validate! }.to raise_error(Metricks::Error)
      end
    end
  end

end
