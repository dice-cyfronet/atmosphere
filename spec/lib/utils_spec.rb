require 'spec_helper'
require 'utils'
#$: << '../../lib'

include Utils

describe Utils do

  context 'min_elements_by' do

    context 'called without block' do

      it 'return empty array for empty input' do
        expect(min_elements_by([])).to be_empty
      end

      it 'returns array with all min input values' do
        expect(min_elements_by([2,3,1,1,5,3])).to eq [1,1]
      end

      it 'returns array with one elements if there is one min value in input' do
        expect(min_elements_by([2,3,4,1,4])).to eq [1]
      end

    end

    context 'called with block' do

      it 'return empty array for empty input when block given' do
        expect(min_elements_by([]) {|e| e.length}).to be_empty
      end

      it 'returns array with all min input values' do
        expect(min_elements_by(['a', 'aa', 'b']) {|e| e.length}).to eq ['a','b']
      end

      it 'returns array with one elements if there is one min value in input' do
        expect(min_elements_by(['ae', 'v', 'qqq']) {|e| e.length}).to eq ['v']
      end

    end
  end

  context 'max_elements_by' do

    context 'called without block' do

      it 'return empty array for empty input' do
        expect(max_elements_by([])).to be_empty
      end

      it 'returns array with all max input values' do
        expect(max_elements_by([2,3,5,1,5,3])).to eq [5,5]
      end

      it 'returns array with one elements if there is one max value in input' do
        expect(max_elements_by([2,3,7,1,4])).to eq [7]
      end

    end

    context 'called with block' do

      it 'return empty array for empty input when block given' do
        expect(max_elements_by([]) {|e| e.length}).to be_empty
      end

      it 'returns array with all max input values' do
        expect(max_elements_by(['a', 'aa', 'b', 'bb']) {|e| e.length}).to eq ['aa','bb']
      end

      it 'returns array with one elements if there is one max value in input' do
        expect(max_elements_by(['ae', 'v', 'qqq']) {|e| e.length}).to eq ['qqq']
      end

    end
  end
end