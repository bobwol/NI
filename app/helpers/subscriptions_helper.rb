module SubscriptionsHelper	

    def subscription_price_table
    	content_tag :table, :class => 'table table-hover subscription-price-table' do
    		content_tag(:thead,
    			content_tag(:tr,
    				content_tag(:th, "Subscription options") +
    				content_tag(:th, "3 months") +
    				content_tag(:th, "6 months") +
    				content_tag(:th, "12 months")
    			)
            ) +
            content_tag(:tbody, 
    			content_tag(:tr,
    				content_tag(:td, "Single purchase") +
    				content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(3,autodebit: false))) +
    				content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(6,autodebit: false))) +
    				content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,autodebit: false)))
    			) +
    			content_tag(:tr,
    				content_tag(:td, "Ongoing Automatic debit") +
    				content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(3,autodebit: true))) +
    				content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(6,autodebit: true))) +
    				content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,autodebit: true)))
    			)
    		)
    	end
    end

end
