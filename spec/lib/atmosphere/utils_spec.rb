require 'spec_helper'
require 'atmosphere/utils'
# $: << '../../lib'

describe Atmosphere::Utils do
  include Atmosphere::Utils

  context 'min_elements_by' do

    context 'called without block' do

      it 'return empty array for empty input' do
        expect(min_elements_by([])).to be_empty
      end

      it 'returns array with all min input values' do
        expect(min_elements_by([2, 3, 1, 1, 5, 3])).to eq [1, 1]
      end

      it 'returns array with one elements if there is one min value in input' do
        expect(min_elements_by([2,3,4,1,4])).to eq [1]
      end

      it 'excludes nil elements' do
        expect(min_elements_by([2, nil, 3, 4, 1, 4])).to eq [1]
      end

    end

    context 'called with block' do

      it 'return empty array for empty input when block given' do
        expect(min_elements_by([]) { |e| e.length }).to be_empty
      end

      it 'returns first element if array size is one' do
        expect(min_elements_by([1]) { |e| e }).to eq [1]
      end

      it 'returns array with all min input values' do
        expect(min_elements_by(['a', 'aa', 'b']) { |e| e.length }).
          to eq ['a', 'b']
      end

      it 'returns array with one elements if there is one min value in input' do
        expect(min_elements_by(['ae', 'v', 'qqq']) {|e| e.length}).to eq ['v']
      end

      it 'does not raise error if block returns nil' do
        min_elements_by([1, 2, 3,]) { |e| e == 2 ? nil : e }
      end

      it 'excludes elements for which block return nil' do
        expect(min_elements_by([7, 2, 3,]) { |e| e == 2 ? nil : e }).to eq [3]
        expect(min_elements_by([5]) { nil }).to be_empty
      end

      it 'returns empty array if block returns nil for all elements' do
        expect(min_elements_by([1]) { nil }).to eq []
      end

    end
  end

  context 'max_elements_by' do

    context 'called without block' do

      it 'return empty array for empty input' do
        expect(max_elements_by([])).to be_empty
      end

      it 'returns array with all max input values' do
        expect(max_elements_by([2, 3, 5, 1, 5, 3])).to eq [5, 5]
      end

      it 'returns array with one elements if there is one max value in input' do
        expect(max_elements_by([2, 3, 7, 1, 4])).to eq [7]
      end

      it 'excludes nil elements' do
        expect(max_elements_by([2, nil, 3, 4, 1, 4])).to eq [4, 4]
      end

    end

    context 'called with block' do

      it 'return empty array for empty input when block given' do
        expect(max_elements_by([]) {|e| e.length}).to be_empty
      end

      it 'returns array with all max input values' do
        expect(max_elements_by(['a', 'aa', 'b', 'bb']) { |e| e.length}).
          to eq ['aa', 'bb']
      end

      it 'returns array with one elements if there is one max value in input' do
        expect(max_elements_by(['ae', 'v', 'qqq']) {|e| e.length}).to eq ['qqq']
      end

      it 'does not raise error if block returns nil' do
        max_elements_by([1, 2, 3,]) { |e| e == 2 ? nil : e }
      end

      it 'excludes elements for which block return nil' do
        expect(max_elements_by([7, 2, 3,]) { |e| e == 2 ? nil : e }).to eq [7]
      end

      it 'returns empty array if block returns nil for all elements' do
        expect(max_elements_by([1]) { nil }).to eq []
      end

    end
  end
end
