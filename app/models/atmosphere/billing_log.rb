# == Schema Information
#
# Table name: billing_logs
#
#  id            :integer          not null, primary key
#  timestamp     :datetime         not null
#  appliance     :string(255)      default("unknown appliance"), not null
#  fund          :string(255)      default("unknown fund"), not null
#  actor         :string(255)      default("unknown billing actor"), not null
#  message       :string(255)      default("appliance prolongation"), not null
#  currency      :string(255)      default("EUR"), not null
#  amount_billed :integer          default(0), not null
#  user_id       :integer
#

# This table constitutes a relational log for the billing service. Each
# controller and service which performs billing operations should write to
# this log.
# This is a standalone class - it is not directly related to any other classes
# in the model; instead it preserves searchable data in the form of strings
# Note: the 'actor' column should be used to specify which controller/service
# added the given log entry.

module Atmosphere
  class BillingLog < ActiveRecord::Base
    belongs_to :user,
               class_name: 'Atmosphere::User'

    validates :appliance, presence: true
    validates :fund, presence: true
    validates :actor, presence: true
    validates :amount_billed, numericality: true

    # This gets less then exactly last year: it gets all logs up to the first
    # day of the month that was 11 months before
    scope :last_year, -> {
      where(timestamp: (Time.now - 11.months).beginning_of_month..Time.now)
    }

    # Turns logs into data series by month
    # Ensures 0 sum for month with no data
    def self.month_data_series(logs)
      12.times.map do |i|
        month_date = Date.today - 11.months + i.months
        month_sum = logs.detect do |l|
          l[0][1].month == month_date.month && l[0][1].year == month_date.year
        end
        month_sum ? month_sum[1] : 0
      end
    end

    scope :sum_currency_by_month, -> do
      group(['currency', "DATE_TRUNC('month', timestamp)"]).
        sum(:amount_billed)
    end
  end
end
