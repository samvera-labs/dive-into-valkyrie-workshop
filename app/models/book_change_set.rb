class BookChangeSet < Valkyrie::ChangeSet
  property :title
  property :author
  property :series
  property :alternate_ids

  validates :title, presence: true
  validates :author, presence: true
end
