module Atmosphere
  module Utils
    def min_elements_by(arr, &block)
      if block_given?
        min_elements_by_with_block(arr, &block)
      else
        min_elements_by_without_block(arr)
      end
    end

    def max_elements_by(arr, &block)
      if block_given?
        max_elements_by_with_block(arr, &block)
      else
        max_elements_by_without_block(arr)
      end
    end

    private

    def min_elements_by_with_block(arr, &block)
      min_elements, arr = first_elements_and_residue(arr, &block)
      return [] if arr.empty? && min_elements.nil?
      arr.each do |e|
        current_min_elements_value = yield(min_elements.first)
        element_value = yield(e)
        next unless current_min_elements_value && element_value

        if current_min_elements_value > element_value
          min_elements = [e]
        elsif current_min_elements_value == element_value
          min_elements << e
        end
      end
      min_elements
    end

    def first_elements_and_residue(arr)
      arr.compact!
      return [nil, []] if arr.empty?
      first_el = arr.shift

      until yield(first_el) || arr.empty?
        first_el = arr.shift
      end
      first_elements = if yield(first_el).nil?
                         []
                       else
                         [first_el]
                       end
      [first_elements, arr]
    end

    def min_elements_by_without_block(arr)
      arr.compact!
      return [] if arr.empty?
      min_elements = [arr.shift]
      arr.each do |e|
        if min_elements.first > e
          min_elements = [e]
        elsif min_elements.first == e
          min_elements << e
        end
      end
      min_elements
    end

    def max_elements_by_with_block(arr, &block)
      max_elements, arr = first_elements_and_residue(arr, &block)
      return [] if arr.empty? && max_elements.nil?
      arr.each do |e|
        current_max_elements_value = yield(max_elements.first)
        element_value = yield(e)
        next unless current_max_elements_value && element_value

        if current_max_elements_value < element_value
          max_elements = [e]
        elsif current_max_elements_value == element_value
          max_elements << e
        end
      end
      max_elements
    end

    def max_elements_by_without_block(arr)
      arr.compact!
      return [] if arr.empty?
      max_elements = [arr.shift]
      arr.each do |e|
        if max_elements.first < e
          max_elements = [e]
        elsif max_elements.first == e
          max_elements << e
        end
      end
      max_elements
    end
  end
end
