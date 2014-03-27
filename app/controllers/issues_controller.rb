class IssuesController < ApplicationController

  # Cancan authorisation
  load_and_authorize_resource :except => [:index]

  newrelic_ignore :only => [:email, :email_non_subscribers, :email_others]

  # So that iOS can post
  # skip_before_filter :verify_authenticity_token, :only => [:show]

  # Devise authorisation
  # before_filter :authenticate_user!, :except => [:show, :index]

  # GET /issues
  # GET /issues.json

  def import
    @issue = Issue.find(params[:issue_id])
    @issue.import_articles_from_bricolage
    redirect_to issue_path(@issue)
  end

  def import_images
    @issue = Issue.find(params[:issue_id])
    @issue.articles.each do |article|
      article.import_media_from_bricolage
    end
    redirect_to issue_path(@issue)
  end

  def import_categories
    @issue = Issue.find(params[:issue_id])
    @issue.articles.each do |article|
      article.import_categories_from_source
    end
    redirect_to issue_path(@issue)
  end

  def index
    # @issues = Issue.all
    # Pagination
    # @issues = Issue.order("release").reverse_order.page(params[:page]).per(2)
    # Search
    # @issues = Issue.search(params)
    # TOFIX: TODO: Search + pagination?
    # @issues = Issue.order("release").reverse_order.page(params[:page]).per(2).search(params)

    @issues = Issue.search(params, current_user.try(:admin?))
    @json_issues = Issue.select {|i| i.published?}.sort_by { |i| i.release }.reverse

    # Set meta tags
    @page_title = "Magazine archive"
    @page_description = "An archive of all the New Internationalist magazines available as digital editions."

    set_meta_tags :title => @page_title,
                  :description => @page_description,
                  :keywords => "new, internationalist, magazine, archive, digital, edition",
                  :canonical => issues_url,
                  :open_graph => {
                    :title => @page_title,
                    :description => @page_description,
                    #:type  => :magazine,
                    :url   => issues_url,
                    :image => @issues.sort_by{|i| i.release}.last.try(:cover_url, :thumb2x).to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@ni_australia",
                    :creator => "@ni_australia",
                    :title => @page_title,
                    :description => @page_description,
                    :image => {
                      :src => @issues.sort_by{|i| i.release}.last.try(:cover_url, :thumb2x).to_s
                    }
                  }

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @issues, callback: params[:callback] }
      format.json { render callback: params[:callback], json: Issue.issues_index_to_json(@json_issues) }
    end
  end

  def email
    @issue = Issue.find(params[:issue_id])
    # sections_of_articles_definitions
    
    # Set meta tags
    @page_title = @issue.title
    @page_description = "Read the #{@issue.release.strftime("%B, %Y")} digital edition of the New Internationalist magazine - #{@issue.title}"

    set_meta_tags :title => @page_title,
                  :description => @page_description,
                  :keywords => "new, internationalist, magazine, digital, edition, #{@issue.title}",
                  :open_graph => {
                    :title => @page_title,
                    :description => @page_description,
                    #:type  => :magazine,
                    :url   => issue_url(@issue),
                    :image => @issue.cover_url(:thumb2x).to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@ni_australia",
                    :creator => "@ni_australia",
                    :title => @page_title,
                    :description => @page_description,
                    :image => {
                      :src => @issue.cover_url(:thumb2x).to_s
                    }
                  }
    respond_to do |format|
      format.html { render :layout => 'email' }
      format.text { render :layout => false }
    end
  end

  def email_non_subscribers
    @issue = Issue.find(params[:issue_id])

    respond_to do |format|
      format.html { render :layout => 'email' }
      format.text { render :layout => false }
    end
  end

  def email_others
    @issue = Issue.find(params[:issue_id])

    respond_to do |format|
      format.html { render :layout => 'email' }
      format.text { render :layout => false }
    end
  end

  def zip
    @issue = Issue.find(params[:issue_id])
    @issue.zip_for_ios
    redirect_to @issue, notice: "Zip created."
  end

  # GET /issues/1
  # GET /issues/1.json
  def show
    # @issue = Issue.find(params[:id])
    # TOFIX: Sort articles by :position using jquery

    # Load section definitions
    #sections_of_articles_definitions
    #moved to the model
    
    # Set meta tags
    @page_title = @issue.title
    @page_description = "Read the #{@issue.release.strftime("%B, %Y")} digital edition of the New Internationalist magazine - #{@issue.title}"

    set_meta_tags :title => @page_title,
                  :description => @page_description,
                  :keywords => "new, internationalist, magazine, digital, edition, #{@issue.title}",
                  :canonical => issue_url(@issue),
                  :open_graph => {
                    :title => @page_title,
                    :description => @page_description,
                    #:type  => :magazine,
                    :url   => issue_url(@issue),
                    :image => @issue.cover_url.to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@ni_australia",
                    :creator => "@ni_australia",
                    :title => @page_title,
                    :description => @page_description,
                    :image => {
                      :src => @issue.cover_url.to_s
                    }
                  }

    respond_to do |format|
      format.html # show.html.erb
      if request.post?
        if request_has_valid_itunes_receipt
          format.json { render json: { :id => @issue.id, :name => @issue.number, :publication => @issue.release, :zipURL => @issue.zip.url } }
        else
          render nothing: true, status: :forbidden
        end
      else
        format.json { render json: issue_show_to_json(@issue) }
      end
    end
  end

  def issue_show_to_json(issue)
    issue.to_json(
      #not super dry, see format block in #show
      # this is everything you should see about an issue without purchasing/subscribing
      # hoping that the only pay-walled content is :body
      # this isn't used by the app - we get it from the issues.json
      #:only => [:title, :id, :number, :editors_name, :editors_photo, :release, :cover],
      #:methods => [:editors_letter_html],
      :only => [],
      :include => { 
        :articles => Issue.article_information_to_include_in_json_hash,
      } 
    )
  end

  # GET /issues/new
  # GET /issues/new.json
  def new
    # @issue = Issue.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @issue }
    end
  end

  # GET /issues/1/edit
  def edit
    # @issue = Issue.find(params[:id])
    # Use cancan to check for individual authorisation
    # authorize! :update, @issue

    set_meta_tags :title => "Edit this Issue"
  end

  # POST /issues
  # POST /issues.json
  def create
    # @issue = Issue.new(params[:issue])

    respond_to do |format|
      if @issue.save
        format.html { redirect_to @issue, notice: 'Issue was successfully created.' }
        format.json { render json: @issue, status: :created, location: @issue }
      else
        format.html { render action: "new" }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /issues/1
  # PUT /issues/1.json
  def update
    # @issue = Issue.find(params[:id])

    respond_to do |format|
      if @issue.update_attributes(params[:issue])
        format.html { redirect_to @issue, notice: 'Issue was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issues/1
  # DELETE /issues/1.json
  def destroy
    # @issue = Issue.find(params[:id])
    # For some reason @issue.destroy doesn't work anymore postgres?
    @issue.destroy
    # @issue.delete

    respond_to do |format|
      format.html { redirect_to issues_url }
      format.json { head :no_content }
    end
  end

  private

    # TOFIX: iTunes receipt validation is also in articles_controller.rb and user.rb
    # Ask Pix how to dry up private methods.

    def request_has_valid_itunes_receipt
      if !request.post?
        return false
      end

      # send the request to itunes connect

      if Rails.env.production?
        itunes_url = ENV["ITUNES_VERIFY_RECEIPT_URL_PRODUCTION"]
      else
        itunes_url = ENV["ITUNES_VERIFY_RECEIPT_URL_DEV"]
      end

      # TODO: Remove this line before launch.. forcing dev itunes receipt validation
      itunes_url = ENV["ITUNES_VERIFY_RECEIPT_URL_DEV"]

      uri = URI.parse(itunes_url)
      http = Net::HTTP.new(uri.host, uri.port)

      json = { "receipt-data" => request.raw_post, "password" => ENV["ITUNES_SECRET"] }.to_json
      http.use_ssl = true
      api_response, data = http.post(uri.path,json)

      # Do a first check to see if the receipt is valid from iTunes
      if JSON.parse(api_response.body)["status"] != 0
        logger.warn "receipt-data: #{request.raw_post}"
        return false
      end

      # Check purchased issues from receipts
      purchased_issue_numbers = purchased_issues_from_receipts(api_response.body)

      # Check purchased subscriptions from receipts
      subscription_receipt_valid = false

      if latest_subscription_expiry_from_recepits(api_response.body) > DateTime.now
        subscription_receipt_valid = true
      end

      # Check to see if those receipts allow the person to read this article
      if subscription_receipt_valid
        logger.info "This receipt has a valid subscription."
      elsif purchased_issue_numbers.include?(@article.issue.number.to_s)
        logger.info "This receipt includes issue: #{@article.issue.number}"
      else
        logger.warn "This receipt doesn't include access to this article."
        return false
      end

      logger.info "post itunes"
      return true
    end

    def purchased_issues_from_receipts(response)
      purchases = JSON.parse(response)['receipt']['in_app']

      issues_purchased = []

      purchases.each do |item|
          if item['product_id'].include?('single')
              issues_purchased << item['product_id'][0..2]
              # TODO: check if purchase already exists and if not, create a new one
          end
      end

      logger.info "Issues purchased: "
      logger.info issues_purchased

      return issues_purchased
    end

    def latest_subscription_expiry_from_recepits(response)
      purchases = JSON.parse(response)['receipt']['in_app']

      subscriptions = []
      latest_expiry = "0"

      purchases.each do |item|
          if item['product_id'].include?('month')
              if item['expires_date_ms'].nil?
                  # The subscription is non-renewing, generate :expires_date_ms for it.
                  subscription_duration = item['product_id'][0..1].to_i
                  item['expires_date_ms'] = ((Time.at(item['original_purchase_date_ms'].to_i / 1000).to_datetime + subscription_duration.months).to_i * 1000).to_s
                  logger.info "Non-renewing subscription, synthesized date: (#{item['expires_date_ms']})"
              end
              subscriptions << item
              # TODO: check if they already have a subscription in Rails, if not, purchase one
          end
      end

      logger.info "Susbcriptions purchased: "
      logger.info subscriptions

      if not subscriptions.empty?
          latest_expiry = subscriptions.sort_by{ |x| x["expires_date_ms"]}.last["expires_date_ms"]
      end

      sec = (latest_expiry.to_f / 1000).to_s

      latest_sub_date = DateTime.strptime(sec, '%s')

      logger.info "Latest subscription expiry date: "
      logger.info latest_sub_date

      return latest_sub_date
    end

    def secret_matches(request)
      # Check secret from iOS matches
      # Now checking iOS receipt........
      secret = Base64.decode64(request.raw_post)
      if secret == ENV["RAILS_ISSUE_SECRET"]
        return TRUE
      else
        return FALSE
      end
    end

end
