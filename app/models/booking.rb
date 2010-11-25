class Booking < ActiveRecord::Base
  attr_accessible :date, :quantity, :expiry_date, :buy_price, :sell_price, :cost
  
  belongs_to :security
  belongs_to :portfolio
end
