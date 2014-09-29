module Atmosphere
  class FlavorsWithRequirements
    def initialize(flavors = VirtualMachineFlavor, options)
        @options = options
        @flavors = flavors
    end

    def find
      query = nil
      query = and_query(query, qteq_cpu) if @options[:cpu]
      query = and_query(query, qteq_mem) if @options[:memory]
      query = and_query(query, qteq_hdd) if @options[:hdd]

      @flavors.where(query || {})
    end

    private

    def and_query(existing_query, new_constraint)
      existing_query ? existing_query.and(new_constraint) : new_constraint
    end

    def qteq_cpu
      qteq(:cpu)
    end

    def qteq_mem
      qteq(:memory)
    end

    def qteq_hdd
      qteq(:hdd)
    end

    def qteq(field)
      table[field].gteq(@options[field])
    end

    def table
      VirtualMachineFlavor.arel_table
    end
  end
end