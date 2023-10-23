json.extract! book, :id, :title, :author, :series, :alternate_ids, :created_at, :updated_at
json.url book_url(book, format: :json)
