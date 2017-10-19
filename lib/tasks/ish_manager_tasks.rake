
def puts! a, b=''
  puts "+++ +++ #{b}"
  puts a.inspect
end

namespace :ish_manager do

  desc "every user needs a user_profile"
  task :generate_user_profiles => :environment do
    User.all.map do |u|
      unless u.profile
        p = ::IshModels::UserProfile.new :email => u.email, :user => u, :role_name => :guy
        u.profile = p
        u.save && p.save && print('.')
      end
    end
    puts 'OK'
  end

  desc 'watch the stocks'
  task :watch_stocks => :environment do
    stocks = IshModels::StockWatch.where( :notification_type => :EMAIL )
    while true
      print '.'
      stocks.each do |stock|
        begin
          Timeout::timeout( 10 ) do
            r = HTTParty.get "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=#{stock.ticker}&interval=1min&apikey=X1C5GGH5MZSXMF3O"
            r = JSON.parse( r.body )['Time Series (1min)']
            r = r[r.keys.first]['4. close'].to_f
            if stock.direction == :ABOVE &&  r >= stock.price ||
               stock.direction == :BELOW && r <= stock.price
              IshManager::ApplicationMailer.stock_alert( stock ).deliver
            end
          end
        rescue Exception => e
          puts! e, 'e in :watch_stocks'
        end
      end
      sleep 60
    end
  end

end
