class PortfoliosController < ApplicationController
  
  require 'csv'


  
  #auto_complete_for :security, :ticker
  
  def create
    #@portfolio = current_user.portfolios.create!(params[:portfolio])
    @portfolio = current_user.portfolios.new(params[:portfolio])
    
    #This doesn't allow setting of the values in the intermediary table so that should be done after.
    #Tried to do this on the after_save on the portfolio model but that didn't work. Looks like the holding is not yet created
    #at that time.
    
    @portfolio.benchmark_id = Security.find_by_ticker(params[:portfolio][:benchmark]).id
    
    if @portfolio.save then
      @portfolio.holdings.create!(:admin => @portfolio.admin, :show_in_graph => @portfolio.show_in_graph, :user_id => current_user.id)
      flash[:success] = "Portfolio saved" 
      redirect_to :controller => 'pages', :action => 'show_portfolios', :id => current_user.id
    else 
      render :action => 'show_portfolios', :id => current_user.id
    end  
    
    
  end
  
  def destroy
    Portfolio.find(params[:id]).destroy
    redirect_to :controller => 'pages', :action => 'show_portfolios'
  end   
  
  def show_holdings
    @portfolio = Portfolio.find(params[:id])
    @holdings = @portfolio.holdings.paginate(:page => params[:page])   
  end 
  
  def show_cashflows
    @portfolio = Portfolio.find(params[:id])
    @cashflows = @portfolio.cashflows.paginate(:page => params[:page]) 
    @cashflow = @portfolio.cashflows.new 
  end
  
  def show_transactions
    @portfolio = Portfolio.find(params[:id])
    @transactions = @portfolio.transactions.paginate(:page => params[:page])
    @transaction = @portfolio.transactions.new
    
  end  
  

    
  def show_bookings
    @portfolio = Portfolio.find(params[:id])
    @bookings = @portfolio.bookings.paginate(:page => params[:page])
  end  
  
  def auto_complete_for_security_description
    description = params[:security][:description]
    @securities = Security.find(:all, :conditions => ["name like :ticker or ticker like :ticker", {:ticker => "%"+description+"%" }])
    render :layout => false
  end
  
  def csv_import 
  #Replaced by the fastcsv loader. To be deleted at later point  
    portfolio = Portfolio.find(params[:id])
    portfolio.transactions.destroy_all
    portfolio.bookings.destroy_all
    #benchmark = Security.find(portfolio.benchmark_id)
    
    parsed_file=CSV::Reader.parse(params[:dump][:file])
    n=0
    parsed_file.shift
    parsed_file.each  do |row|
      security = find_or_create_security(row[4])  
      #@earliest_date = Date.today()

      if security
        if row[2]=="A" or row[2]=="V" or row[2]=="CPS" or row[2]=="VOP"
        
          t=portfolio.transactions.new
          #Keytrade specific loader
         
          t.date=row[0]
          
          t.security_id = security.id
          #t.stock_id=row[1]
          if row[2]=="A"
            t.operation = "Buy"
          elsif row[2] == "V" or row[2]=="VOP"
            t.operation = "Sell"
          else
            t.operation = "Dividend"
          end     
        
          if row[2]=="A" or row[2]=="V" or row[2]=="VOP"
            price = (row[6].gsub(/\s+/,'').to_f / row[7].gsub(/\s+/,'').to_f )
            amount = row[8].gsub(/\s+/,'').to_f
            quantity = row[3].gsub(/\s+/,'').to_f
            cost = (amount).abs
            t.quantity=quantity
            t.price=price
            t.cost=(amount-price*quantity).abs
          else
            t.dividend = row[8].gsub(/\s+/,'').to_f
          end
          
          
          
          if t.save
            n =+ 1 
            GC.start if n%50==0
            security.load_quotes(t.date)
            #@earliest_date = t.date if t.date < @earliest_date
          end  
           
        end
      else
        logger.info("Security #{row[4]} not found!")
      end
      
    end  
    
    flash.now[:message]="CSV Import Successful,  #{n} new records added to data base"
   
    #if t.save
    #  n=n+1
    #  GC.start if n%50==0
    #end
    
    portfolio.update_all_bookings
    #this code exists twice: here and in the controller.
    
    #raise portfolio.transactions.first.id.inspect
    #benchmark.load_quotes(portfolio.transactions.first.date)
    #benchmark.load_quotes(@earliest_date)
    portfolio.load_benchmark_quotes
    
    flash.now[:message]="CSV Import Successful,  #{n} new records added to data base"
    
    redirect_to :controller => 'portfolios', :action => 'show_transactions', :id => portfolio.id
    
  end
  
  
  
  
  
end


