# == Schema Information
#
# Table name: funds
#
#  id                 :integer          not null, primary key
#  name               :string(255)      default("unnamed fund"), not null
#  balance            :integer          default(0), not null
#  currency_label     :string(255)      default("EUR"), not null
#  overdraft_limit    :integer          default(0), not null
#  termination_policy :string(255)      default("suspend"), not null
#

require 'spec_helper'

describe Fund do
  pending "add some examples to (or delete) #{__FILE__}"
end
