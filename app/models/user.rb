# == Schema Information
# Schema version: 20100712123937
#
# Table name: users
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class User < ActiveRecord::Base
  attr_accessible :name, :email, :password, :password_confirmation
  attr_accessor :password
  
  has_many :microposts, :dependent => :destroy
  
  has_many :relationships, :foreign_key => "follower_id", :dependent => :destroy
  has_many :reverse_relationships, :foreign_key => "followed_id",
                                    :class_name => "Relationship",
                                    :dependent => :destroy
  
  has_many :following, :through => :relationships, :source => :followed
  has_many :followers, :through => :reverse_relationships, :source => :follower
  
  has_many :holdings, :dependent => :destroy
  has_many :portfolios, :through => :holdings, :uniq => true
    
  before_save :encrypt_password
  
  EmailRegex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  
  validates_presence_of :name, :email
  validates_length_of :name, :maximum => 50
  validates_format_of :email, :with => EmailRegex
  validates_uniqueness_of :email, :case_sensitive => false
  
  validates_confirmation_of :password
  
  validates_presence_of :password
  validates_length_of :password, :within => 6..40
  
  #Returns true if the user's password matches the submitted password
  def has_password?(submitted_password)
    encrypted_password == encrypt(submitted_password)
  end
  
  def remember_me!
    self.remember_token = encrypt("#{salt}--#{id}--#{Time.now.utc}")
    save_with_validation(false)
  end  
  
  def self.authenticate(email, submitted_password)
    user = User.find_by_email(email)
    return nil if user.nil?
    return user if user.has_password?(submitted_password)
  end  
  
  def feed
    Micropost.all(:conditions => ["user_id = ?", id])
  end  
  
  def following?(followed)
    relationships.find_by_followed_id(followed)
  end  
  
  def follow!
    relationships.create!(:follwed_id => followed.id)
  end  
  
  def unfollow!(followed)
    relationships.find_by_followed_id(followed).destroy
  end  
  
  def calculate_profits
    profits = Portfolio.find_by_sql("select date, invested, profit, cash, cash_tracker_profit from (select date, sum(invested) as invested, sum(profit) as profit, sum(cash) as cash, sum(cash_tracker_profit) as cash_tracker_profit from" +
    "(Select pbb.date, sum(pbb.invested) as invested, sum(pbb.profit) as profit, sum(pbb.cash) as cash, sum(pbb.cash_tracker_profit) as cash_tracker_profit from " +
    "(select q.date, b.quantity * b.buy_price as invested," +
    "CASE WHEN b.sell_price > 0 THEN (b.sell_price-b.buy_price)*b.quantity-b.cost ELSE (q.close-b.buy_price)*b.quantity-b.cost END as profit, 0 as cash, 0 as cash_tracker_profit " +
    "from bookings b join portfolios pf on pf.id = b.portfolio_id " +
    "join quotes q on q.security_id = b.security_id " +
    "where ((q.date >= b.date and q.date < b.expiry_date) or (q.date >= b.date and length(b.expiry_date) is null))) " +
    "as pbb group by pbb.date " +
    "union " +

    "select ctp.date, sum(invested) as invested, sum(profit) as profit, sum(cash) as cash, sum(cash_tracker_profit) as cash_tracker_profit from" +
    "(select q.date,  0 as invested, 0 as profit, cf.amount as cash, (((q.close/q2.close)-1)*cf.amount) as cash_tracker_profit from " +
    "cashflows cf join portfolios pf on pf.id = cf.portfolio_id " +
    "join quotes q on q.security_id = pf.benchmark_id " +
    "join quotes q2 on q2.security_id = pf.benchmark_id and q2.date = cf.date " +
    "where q.date > cf.date) " +
    "as ctp group by ctp.date) group by date) where cash_tracker_profit <> 0 ")
  end
  
  def create_timeline(profits)
    
    data = Hash.new
    n=0
    profits.each do |profit|
      data[profit.date.to_date] = { :profit => profit.profit, :cash_tracker_profit => profit.cash_tracker_profit }
      
      n+=1
    end  
    data
    
  end
  
  def create_annotations
    annotations = Hash.new
    messages = Hash.new
    messages2 = Hash.new
    
    portfolios = self.portfolios
    
    portfolios.each do |p|  
      p.transactions.each do |t|
        messages[t.date.to_date] = [t.security_id.to_s,t.operation + ' ' + t.quantity.to_s + " @ " + t.price.to_s]
      end
    end
    
    portfolios.each do |p|
      p.cashflows.each do |cf|
        messages2[cf.date.to_date] = ['Increased amount by ' + cf.amount.to_s]
        #messages2[1.day.ago.to_date] = ["yesterday", "all my troubles seemed so far away"]
      end
    end

    
    #annotations[:profit] = messages
    annotations[:cash_tracker_profit] = messages2
    
    #logger.info(annotations)
    #annotations2 = Hash.new
    #annotations2 = {
    #      :profit => { 10.day.ago.to_date => ["yesterday", "all my troubles seemed so far away"]},
    #      :cash_tracker_profit => { 100.day.ago.to_date => ["last tuesday"], 50.days.ago.to_date => ["last monday"]}
    #    }
    #logger.info(annotations2)
    
    #cash_transactions = self.cash_transactions
    
    #cash_transactions.each do |t|  
    #  messages2[t.date] = 'Increased amount by ' + t.amount.to_s 
    #end
    
    #annotations = { :profit => messages, :cash_tracker_profit => messages2 }
    
    annotations
    
  end
  
  def load_quotes
    self.portfolios.each do |p|
      p.securities.each do |s|  
        s.load_quotes_and_benchmark(p)
      end
    end
  end  
  
  private 
  
    def encrypt_password
      unless password.nil?
        self.salt = make_salt
        self.encrypted_password = encrypt(password)
      end
    end  
  
    def encrypt(string)
      secure_hash("#{salt}#{string}")
    end  
  
    def make_salt
      secure_hash("#{Time.now.utc}#{password}")
    end  
  
    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end  
  
end
