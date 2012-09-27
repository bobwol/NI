class Article < ActiveRecord::Base
  belongs_to :issue
  attr_accessible :author, :body, :publication, :teaser, :title, :trialarticle

  include Tire::Model::Search
  include Tire::Model::Callbacks

  # Doesn't seem to list all of the articles when no params.
  # def self.search(params)
  #   tire.search(load: true) do
  #     query { string params[:query]} if params[:query].present?
  #   end
  # end

end
