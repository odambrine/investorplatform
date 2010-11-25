class Security < ActiveRecord::Base
  
  require 'yahoofinance'
  
  attr_accessible :name, :ticker, :type
  
  has_many :transactions, :dependent => :destroy, :order => "date ASC"
  has_many :portfolios, :through => :transactions
  has_many :bookings, :dependent => :destroy
  has_many :quotes, :dependent => :destroy, :order => "date ASC"
  
  validates_uniqueness_of :ticker
  validates_presence_of :name,
                          :message => "Stock not found on Yahoo Finance."
  before_validation_on_create :update_stock_information
  
  BENCHMARKS =[
    [ "Bel-20", "^BFX"],
    ]
  
  def load_quotes_and_benchmark(portfolio)
    start_date = self.load_quotes
    
    Security.find(portfolio.benchmark_id).load_quotes(start_date)
  end  
  
  def load_quotes(*start) 
    
    #if the date is given, take that. Else take the oldest transaction.
    if not start.empty?
      start_date = start.first
    elsif not self.transactions.empty?
      start_date = self.transactions.first.date
    end 
    
    #If the start date is already in the quote table, there's no need to reload so we can take the latest.
    if Quote.find_by_security_id_and_date(self.id, start_date)
      start_date = self.quotes.last.date.tomorrow
    end
    
    
    
    if start_date < Date.today() then
      temp_date = start_date.strftime("%Y-%m-%d")   
      YahooFinance::get_historical_quotes(self.ticker, Date.parse(temp_date), Date.today()) do |hq|
        create_quote(self.id, hq[0], hq[1], hq[2], hq[3], hq[4], hq[5])
      end 
      
    
      #if a stock gets delisted, repeat the final quote until today
      last_quote = self.quotes.last
      
      if last_quote
        temp_date = last_quote.date.tomorrow
       
        while temp_date < Date.today()
            logger.info("Created for temp_date #{temp_date} price #{last_quote.close}")
            create_quote(self.id, temp_date.strftime("%d-%m-%Y") , last_quote.open, last_quote.high, last_quote.low, last_quote.close, last_quote.volume) if temp_date.wday != 0 && temp_date.wday != 6
            temp_date = temp_date.tomorrow
        end
      end 
    end  
    
    start_date 
    
                                           
  end
  
  
  
  def create_quote(security_id, date, open, high, low, close, volume)
    if not Quote.find_by_security_id_and_date(security_id, date)
      quote = Quote.new
      quote.security_id = security_id
      quote.date = date
      quote.open = open
      quote.high = high
      quote.low = low
      quote.close = close
      quote.volume = volume
      quote.save
    end  
  end
  
   
  
  
  
  protected

  def quote
    @quote ||= YahooFinance::get_standard_quotes(self.ticker)[self.ticker]
  end

  def update_stock_information
    self.name = @quote.name if quote.valid?
  end
  
  
end  