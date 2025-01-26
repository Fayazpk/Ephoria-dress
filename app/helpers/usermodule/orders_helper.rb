# C:\Users\Admin\Desktop\ruby\euphoria\app\helpers\usermodule\orders_helper.rb
module Usermodule::OrdersHelper 
  def status_badge_class(status)
    case status
    when 'pending' then 'bg-yellow-200 text-yellow-800'
    when 'processing' then 'bg-blue-200 text-blue-800'
    when 'shipped' then 'bg-purple-200 text-purple-800'
    when 'delivered' then 'bg-green-200 text-green-800'
    when 'cancelled' then 'bg-red-200 text-red-800'
    else 'bg-gray-200 text-gray-800'
    end
  end
end