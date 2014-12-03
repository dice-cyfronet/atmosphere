module Atmosphere
  module FundsHelper

    def fund_balance_decorator(balance)
      "#{balance / 10000}.#{balance % 10000}"
    end

  end
end
