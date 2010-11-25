class Portfolio < ActiveRecord::Base
  attr_accessible :name
  
  attr_accessor :admin, :show_in_graph, :benchmark
  
  has_many :holdings, :dependent => :destroy
  has_many :users, :through => :holdings, :uniq => true
  has_many :cashflows, :dependent => :destroy, :order => "date ASC"
  has_many :transactions, :dependent => :destroy, :order => "date ASC"
  has_many :securities, :through => :transactions
  has_many :bookings, :dependent => :destroy
  has_many :import_tables, :dependent => :destroy
  
  #still to add: belongs to stock via benchmark
  
  validates_presence_of :name, :benchmark_id
  
  
  def after_initialize
    self.admin = true
    self.show_in_graph = true
  end
  
  def update_all_bookings
    
    self.securities.each do |s|
      self.update_bookings(s)
    end    
  end
  
  def update_bookings(security)
    Booking.delete_all(["Portfolio_id = ? AND Security_id = ?", self.id, security.id])
    transactions = self.transactions.find_all_by_security_id(security)
    
    transactions.each do |t|
      quantity=0
      
      if t.operation == 'Buy'
        buy_booking = self.bookings.new
        buy_booking.date = t.date
        buy_booking.security_id = t.security_id
        buy_booking.quantity = t.quantity
        buy_booking.buy_price = t.price
        buy_booking.cost = t.cost
        buy_booking.dividend = 0
        buy_booking.save
      elsif t.operation == 'Sell'
        cost = 0
        price = 0
        quantity = 0
        #First set expiration date of all bookings related to transactions of this stock 
        bookings = self.bookings.find_all_by_security_id(security)
        bookings.each do |b|
          if not b.sell_price and not b.expiry_date           
              cost += b.cost
              price += b.buy_price * b.quantity
              quantity += b.quantity
              b.expiry_date = t.date
              b.save
          end  
        end  
        price = price / quantity if quantity!=0

        #Then create a booking for the remaining shares
        if t.quantity < quantity
          buy_booking = self.bookings.new
          buy_booking.security_id = t.security_id
          buy_booking.date = t.date
          buy_booking.quantity = quantity - t.quantity
          buy_booking.buy_price = price
          buy_booking.cost = 0
          buy_booking.dividend = 0
          buy_booking.save
        end  

        #Finally, create a sell booking
        sell_booking = self.bookings.new
        sell_booking.security_id = t.security_id
        sell_booking.date = t.date
        sell_booking.quantity = t.quantity
        sell_booking.buy_price = price
        sell_booking.sell_price = t.price
        sell_booking.cost = cost + t.cost
        sell_booking.dividend = 0
        sell_booking.save


      elsif t.operation == 'Dividend'
        #Coupon
        div_booking = self.bookings.new
        div_booking.security_id = t.security.id
        div_booking.date = t.date
        div_booking.quantity = 0
        div_booking.cost = 0
        div_booking.dividend = t.dividend
        div_booking.save
      end
      
    end  
  end  
  
  def load_benchmark_quotes
    benchmark = Security.find(self.benchmark_id)
    benchmark.load_quotes(self.cashflows.first.date)
    #benchmark.load_quotes(Date.parse('1/1/2005'))
  end  
end
