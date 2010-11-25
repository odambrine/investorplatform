class ImporttablesController < ApplicationController
  
  def show
    
    @import_table = ImportTable.find(params[:id])    
    @import_cells = @import_table.import_cells
    @row_index_max = @import_cells.map { |cell| cell.row_index }.max
    @column_index_max = @import_cells.map { |cell| cell.column_index }.max
    @tables = ActiveRecord::Base.connection.tables.select { |t| t != 'schema_migrations' }
    #@columns = Transaction.column_names.select { |c| c != 'id' && c != 'updated_at' && c!= 'created_at' }
  end
  
  def create
    raise "test".inspect
  end  
  
  def merge
      # Uncomment the following line if you want to debug this method. However,
      # do not forget to uncomment the gem 'ruby-debug' in Gemfile also; this
      # assumes you have the ruby-debug gem installed too, and do the usual
      # thing if not, i.e. sudo gem install ruby-debug. Calling "debugger"
      # inserts a break point when the server hits this point in the
      # application. From that point you can interrogate the Rails state, single
      # step over or into message-sends and so forth. Very useful for debugging!
      # debugger
      

      import_table = ImportTable.find(params[:id])
      portfolio = Portfolio.find(import_table.portfolio_id)
      import_cells = import_table.import_cells
      row_index_max = import_cells.map { |cell| cell.row_index }.max
      column_index_max = import_cells.map { |cell| cell.column_index }.max
      
      portfolio.transactions.delete_all
      portfolio.bookings.delete_all

      # Pull the merge parameters from the POST request. The form sets up the
      # column mappings and merge table choice. Then use a little bit of
      # ActiveRecord introspection to derive the table's class name followed by
      # the class object. We will use this latter object to instantiate the
      # merged records.
      merge = params[:merge]
      #merge_table = merge[:table]
      #klass = ActiveRecord::Base.const_get(ActiveRecord::Base.class_name(""))
      
      
      # Determine which columns have been mapped. Ignore the rest. Intersect the
      # requested column names with actual column names. Perhaps we should abort
      # and display some error message if the intersection proves empty because
      # the user did not select any columns.
      
      
      
      inverted_merge = merge.invert
      #column_names = inverted_merge.keys & Transaction.column_names
      column_names = inverted_merge.keys
     
      column_names.delete ""
      column_names.delete "0"
      column_names.delete "1"
      
      row_indices_ignore = Array.new
      
      merge.each do |key, val|
        if val == "0" then
          row_indices_ignore << ImportCell.find(key).row_index
        end  
      end  
      
      
      
      # Finally, create new instances, one per row. Iterate the rows, then for
      # each row, iterate the mapped columns. Select the matching cell and
      # update the record's corresponding column. Redirect to the merged table
      # when done.
      0.upto(row_index_max) do |row_index|
        row = import_cells.select { |cell| cell.row_index == row_index }
        #instance = klass.new
        
        #debugger
        if !row_indices_ignore.find { |e| e == row_index }
          instance = portfolio.transactions.new
          column_names.each do |column_name|
         
            column_index = inverted_merge[column_name].to_i
            contents = row.select { |cell| cell.column_index == column_index }[0].contents
          
            #translate: ticker to id
            if column_name == 'ticker' && !contents.blank? then
              contents = find_or_create_security(contents).id 
              column_name = 'security_id'
            end
            
            if column_name == "date" then
              temp_date = Date.parse(contents)
              if temp_date.year < 20 then
                year = temp_date.year + 2000
              elsif contents.year < 100 then
                year = temp_date.year + 1900
              else
                year = temp_date.year
              end      
              date = Date.new(year, temp_date.month, temp_date.day)
              instance[column_name] = date
            else  
              instance[column_name] = contents
            end
          end
          instance.save
        end
      end
      
      portfolio.update_all_bookings
      #eval "redirect_to #{merge_table}_path"

      portfolio.load_benchmark_quotes
      portfolio.securities.each do |s|
        s.load_quotes
      end  

      #flash.now[:message]="CSV Import Successful,  #{n} new records added to data base"

      redirect_to :controller => 'portfolios', :action => 'show_transactions', :id => portfolio.id
  end  
end
