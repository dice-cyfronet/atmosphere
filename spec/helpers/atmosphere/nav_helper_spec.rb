require 'spec_helper'

describe Atmosphere::NavHelper do
  include Atmosphere::ApplicationHelper

  describe 'nav_link' do
    before do
      allow(controller).to receive(:controller_name).and_return('foo')
      allow(controller).to receive(:action_name).and_return('foo')
    end

    it "captures block output" do
      expect(nav_link { "Testing Blocks" }).to match(/Testing Blocks/)
    end

    it "performs checks on the current controller" do
      expect(nav_link(controller: :foo)).to match(/<li class="active">/)
      expect(nav_link(controller: :bar)).to_not match(/active/)
      expect(nav_link(controller: [:foo, :bar])).to match(/active/)
    end

    it "performs checks on the current action" do
      expect(nav_link(action: :foo)).to match(/<li class="active">/)
      expect(nav_link(action: :bar)).to_not match(/active/)
      expect(nav_link(action: [:foo, :bar])).to match(/active/)
    end

    it "performs checks on both controller and action when both are present" do
      expect(nav_link(controller: :bar, action: :foo)).to_not match(/active/)
      expect(nav_link(controller: :foo, action: :bar)).to_not match(/active/)
      expect(nav_link(controller: :foo, action: :foo)).to match(/active/)
    end

    it "accepts a path shorthand" do
      expect(nav_link(path: 'foo#bar')).to_not match(/active/)
      expect(nav_link(path: 'foo#foo')).to match(/active/)
    end

    it "passes extra html options to the list element" do
      expect(nav_link(action: :foo, html_options: {class: 'home'})).to match(/<li class="home active">/)
      expect(nav_link(html_options: {class: 'active'})).to match(/<li class="active">/)
    end
  end
end
