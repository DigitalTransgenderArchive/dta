class Posts < ActiveRecord::Base
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  acts_as_ordered_taggable

  paginates_per 10

  # Try building a slug based on the following fields in
  # increasing order of specificity.
  def slug_candidates
    [
        [:created_ym, :title],
        :title,
        [:created_ym, :title, :user]
    ]
  end

  def next
    Posts.where("created > ?", created).order("created DESC").last
  end

  def prev
    Posts.where("created < ?", created).order("created DESC").first
  end

end
