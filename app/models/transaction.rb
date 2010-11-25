class Transaction < ActiveRecord::Base
  attr_accessible :date, :security_id, :operation, :quantity, :price, :cost
  attr_accessor :security
  
  belongs_to :portfolio
  belongs_to :security

  #validates_presence_of :date, :quantity
  #validate :on_weekday?
  
  OPERATION_TYPES =[
    [ "Buy", "Buy" ],
    [ "Sell", "Sell" ],
    [ "Dividend", "Dividend" ]
    ]
    
  def security
    Security.find(self.security_id).name
  end   
    
   private 
   
   #def on_weekday? 
  #   raise self.date.inspect
  #   errors.add("transactions can only be done on weekdays.") if self.date.wday == 0 || self.date.wday == 6 
  # end   
  
end
