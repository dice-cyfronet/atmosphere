module Atmosphere
  module FundsHelper

    def fund_balance_full_precision(balance)
      "#{balance / 10000}.#{balance % 10000}"
    end

  end
end
