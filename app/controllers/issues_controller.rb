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
      if request.post? and secret_matches(request)
        format.json { render json: { :id => @issue.id, :name => @issue.number, :publication => @issue.release, :zipURL => @issue.zip.url } }
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

  def secret_matches(request)
    # Check secret from iOS matches
    secret = request.raw_post

    if secret == ENV["RAILS_ISSUE_SECRET"]
      return TRUE
    else
      return FALSE
    end
  end

end
