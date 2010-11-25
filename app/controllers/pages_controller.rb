class PagesController < ApplicationController
  def home
    @title = "Home"
    if signed_in?
      @micropost = Micropost.new
      @feed_items = current_user.feed.paginate(:page => params[:page])
    end  
  end

  def contact
    @title = "Contact"
  end
  
  def about
    @title = "About"
  end
  
  def help
    @title = "Help"
  end    
  
  def show_portfolios 
       @portfolio = current_user.portfolios.new
       @portfolios = current_user.portfolios.paginate(:page => params[:page])   
  end
  
  def show_dashboard
    current_user.load_quotes
    @profits = current_user.calculate_profits
    @data = current_user.create_timeline(@profits) 
    @annotations = current_user.create_annotations
    
    @chart = GoogleVisualr::AnnotatedTimeLine.new
      @chart.add_column('date' , 'Date')
      @chart.add_column('number', 'Profit')
      @chart.add_column('string', 'title1')
      @chart.add_column('string', 'text1' )
      @chart.add_column('number', 'Cash Tracker Profit' )
      @chart.add_column('string', 'title2')
      @chart.add_column('string', 'text2' )
      
      @chart2 = GoogleVisualr::AnnotatedTimeLine.new
        @chart2.add_column('date' , 'Date')
        @chart2.add_column('number', 'Cash')
        @chart2.add_column('string', 'title1')
        @chart2.add_column('string', 'text1' )
        @chart2.add_column('number', 'Invested')
        @chart2.add_column('string', 'title2')
        @chart2.add_column('string', 'text2' )
     
      
      outer = Array.new
      outer2 = Array.new
      n=0
      @profits.each do |profit|
        outer[n]=[Date.parse(profit.date),profit.profit.to_i,'','',profit.cash_tracker_profit.to_i,'','']
        outer2[n]=[Date.parse(profit.date),profit.cash.to_i,'','',profit.invested.to_i, '','']
        n+=1
      end  
          
      @chart.add_rows(outer)
      @chart2.add_rows(outer2)
      

      options = { :displayAnnotations => true, :displayExactValues => true }
      options.each_pair do | key, value |
        @chart.send "#{key}=", value
        @chart2.send "#{key}=", value
      end
  end  
  
  

end
