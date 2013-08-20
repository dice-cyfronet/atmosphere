require 'spec_helper'

describe ApplicationHelper do
  describe 'current_controller?' do
    before do
      controller.stub(:controller_name).and_return('foo')
    end

    it "returns true when controller matches argument" do
      expect(current_controller?(:foo)).to be_true
    end

    it "returns false when controller does not match argument" do
      expect(current_controller?(:bar)).to_not be_true
    end

    it "should take any number of arguments" do
      expect(current_controller?(:baz, :bar)).to_not be_true
      expect(current_controller?(:baz, :bar, :foo)).to be_true
    end
  end

  describe 'current_action?' do
    before do
      controller.stub(:action_name).and_return('foo')
    end

    it "returns true when action matches argument" do
      expect(current_action?(:foo)).to be_true
    end

    it "returns false when action does not match argument" do
      expect(current_action?(:bar)).to_not be_true
    end

    it "should take any number of arguments" do
      expect(current_action?(:baz, :bar)).to_not be_true
      expect(current_action?(:baz, :bar, :foo)).to be_true
    end
  end
end