module Atmosphere
  module FundsHelper

    def fund_balance_full_precision(balance)
      balance = balance.to_i
      "#{'-' if balance < 0}#{balance.abs / 10000}." +
      "#{(balance.abs % 10000).to_s.rjust(4, '0')}"
    end

  end
end
