class ImportTable < ActiveRecord::Base
  has_many :import_cells, :dependent => :destroy
  belongs_to :portfolio
  
  TRANSACTION_IMPORT_COLUMNS =[
    [ "date", "date" ],
    [ "ticker", "ticker" ],
    [ "operation", "operation" ],
    [ "quantity", "quantity" ],
    [ "price", "price" ],
    [ "cost", "cost" ],
    [ "dividend", "dividend" ]
    ]
  
end
