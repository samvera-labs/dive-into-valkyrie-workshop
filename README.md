# [Dive into Valkyrie](https://samveraconnect2023.sched.com/event/1OmBk)

This repository supports a workshop given at
[Samvera Connect 2023](https://samvera.atlassian.net/wiki/spaces/samvera/pages/2174877699/Samvera+Connect+2023).

Valkyrie is a data persistence library which provides a common interface to multiple backends. There are a growing number of Samvera applications that use Valkyrie including Hyrax. This workshop will introduce core concepts and how they differ from ActiveFedora, ActiveRecord, and ActiveStorage. We’ll build a simple rails application that uses Valkyrie to write metadata to a postgres database and store files on disk.

## Learning Outcomes

We will learn:
1. Familiarity of Data Mapper pattern
   1. Why DataMapper?
   1. Differences with ActiveRecord
1. Familiarity with Valkyrie concepts
   1. Resource
   2. Change Set
   3. Metadata Adapter
   4. Persister
   5. Query Service
      1. Built-in queries
      2. Custom queries
   7. Storage Adapter
1. Understanding how to use Valkyrie in a simple rails application for metadata and file storage
   1. Hands on experience defining resource models and persisting metadata and files
1. Familiarity with available Valkyrie adapters
   1. Bundled in Valkyrie gem
   2. Adapter ecosystem

## Getting Started

This respository includes a new Rails 7.1 application and a `docker-compose.yml` intended to run that application and its dependencies.  The application has the Valkyrie gem configured to use the postgres adapter and disk storage adapter.  We'll use this application as a general workspace throughout the workshop and as the base for our exercises.

To ensure you can run the application, do:
```sh
git clone https://github.com/samvera-labs/dive-into-valkyrie-workshop.git
cd dive-into-valkyrie-workshop
docker compose pull
docker compose up 
```

## Agenda

### Concepts (9:00)

#### ActiveRecord vs. DataMapper
##### ActiveRecord
Convenient!  The model does everything I need!

- In-memory object representation
- Persistance
- Dirty Tracking
- Validation
- Querying
- Callbacks
- Business logic

##### ActiveFedora
Let's add indexing to solr into the ActiveRecord model since we want that too!

- Indexing
- Querying from Solr

With everything bundled together it can be hard to change something without affecting other parts.  For example, validation applies to all save operations no matter the context it is getting called in: controller, batch, or console.  With ActiveFedora certain model operations call solr and others call fedora and it can be hard to know where the separation is.

##### DataMapper
Explode the ActiveRecord monolith into single responsibility objects for greater flexibility.  Now I can swap out any piece for different use cases.  Persisting to different data stores just means using a different persister.  Retrieving from different sources (solr vs fedora) by using different query servies.  Different forms may want to validate data differently or require different fields so use a different change set.

- Resource: in-memory object representation
- Persister: persistence
- Change set: validation, dirty tracking, data coercion
- Query service: retrieving
- Indexer: indexing
- Storage adapter: storing binaries

#### Valkyrie
Valkyrie is a samvera gem that provides a set of tools for implementing the data mapper pattern in a digital repository context.  Noteably it provides a common interface for persisters and query services so different data stores can be used interchangeably.  It provides four adapters for matadata: postgres, fedora, solr, and memory.  [Shared specs](https://github.com/samvera/valkyrie/wiki/Shared-Specs) make it easy to implement new adapters!  Let's dive into each of these five types of objects in more depth now.

### Resources, Persister, and Query services (9:10)

##### Valkyrie::Resource
Define attributes and their types (dry-struct and dry-types).  See <https://github.com/samvera/valkyrie/wiki/Using-Types> for more details on types.  Has default attributes: `id`, `created_at`, `updated_at`, `internal_resource`, `new_record`  That's pretty much it!

##### Persister
Takes care of persisting a resource in a data store.
```ruby
Valkyrie.config.metadata_adapter.persister.save(resource: obj)
Valkyrie.config.metadata_adapter.persister.save_all(resources: [obj1, obj2])
Valkyrie.config.metadata_adapter.persister.delete(resource: obj)
```
See <https://github.com/samvera/valkyrie/wiki/Persistence>

##### Query service
Retrieves data from data store and populates in-memory resources.  Attempts to define a limited number of queries common to all data stores and allows adding custom queries that might be optimized for a particular data store.
```ruby
Valkyrie.config.metadata_adapter.query_service.find_by(id: id)
Valkyrie.config.metadata_adapter.query_service.find_all_of_model(model: Valkyrie::Resource)
Valkyrie.config.metadata_adapter.query_service.find_members
Valkyrie.config.metadata_adapter.query_service.find_parents
```
There are seven queries supported by all adapters and the ability to add custom queries that might be specific to an adapter.  See <https://github.com/samvera/valkyrie/wiki/Queries>

##### Storage Adapter
Stores and retrieves binary content.  Built-in implementations are disk, versioned disk, fedora, and memory.
```ruby
Valkyrie.config.storage_adapter.upload(file:, resoure:, original_filename:)
Valkyrie.config.storage_adapter.find_by(id:)
```
See <https://github.com/samvera/valkyrie/wiki/Storage-&-Files>

#### Exercise 1: Define a resource
(Adapted from <https://github.com/samvera/valkyrie/wiki/Understanding-resources#defining-resources>)

Create model
Edit app/model/book.rb
```ruby
class Book < Valkyrie::Resource
  attribute :alternate_ids, Valkyrie::Types::Array
              .of(Valkyrie::Types::ID)
  attribute :title, Valkyrie::Types::Set
              .of(Valkyrie::Types::String)
              .meta(ordered: true)
  attribute :author, Valkyrie::Types::Set
              .of(Valkyrie::Types::Strict::String)
              .meta(ordered: true)
  attribute :series, Valkyrie::Types::Strict::String
  attribute :member_ids, Valkyrie::Types::Array
              .of(Valkyrie::Types::ID)
end
```

Let's try it out in the rails console inside the container:
```sh
docker-compose exec app /bin/bash
bundle exec rails c
```
```ruby
book = Book.new
book.title = ["Tuesdays at the Castle"]
book.author = "Jessica Day George"
book.author
book.alternate_ids = ["9781599906447"]
book.persisted?
saved_book = Valkyrie.config.metadata_adapter.persister.save(resource: book)
# Persisting doesn't modify the existing book object but returns a new persisted Book object
book.persisted?
saved_book.persisted?
saved_book.id
Valkyrie.config.metadata_adapter.query_service.find_all_of_model(model: Book)
retrieved_book = Valkyrie.config.metadata_adapter.query_service.find_by(id: saved_book.id)
retrieved_book.id
# The two book objects we retrieved are different objects but equal
retrieved_book.object_id == saved_book.object_id
retrieved_book == saved_book
# Besides retrieving by id we can also retrieve from alternate id
Valkyrie.config.metadata_adapter.query_service.find_by_alternate_identifier(alternate_identifier: '9781599906447')
```

Let's make another model so we can explore relationships and files.

Edit app/model/page.rb
```ruby
class Page < Valkyrie::Resource
  attribute :number, Valkyrie::Types::Integer
  attribute :file_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)
end
```

Now in the console try:
```ruby
book = Book.new(title: "Tuesdays at the Castle", author: "Jessica Day George")
book = Valkyrie.config.metadata_adapter.persister.save(resource: book)
page = Page.new
page.number = 1
saved_page = Valkyrie.config.metadata_adapter.persister.save(resource: page)
book.member_ids << saved_page.id
book = Valkyrie.config.metadata_adapter.persister.save(resource: book)
Valkyrie.config.metadata_adapter.query_service.find_members(resource: book).to_a
Valkyrie.config.metadata_adapter.query_service.find_parents(resource: saved_page).to_a
```

Let's look at attaching binary files:
```ruby
upload = ActionDispatch::Http::UploadedFile.new(tempfile: File.new('/rails/README.md'), filename: 'README.md', type: 'text/plain')
file = Valkyrie.config.storage_adapter.upload(file: upload, resource: page, original_filename: 'README.md')
file.id
page.file_ids << file.id
page = Valkyrie.config.metadata_adapter.persister.save(resource: page)
Valkyrie.config.storage_adapter.find_by(id: page.file_ids.first)
size = file.size
sha1 = file.checksum(digests:[Digest::SHA1.new]).first
file.valid?(size: size, digests: {sha1: sha1})
Valkyrie.config.storage_adapter.delete(file.id)
Valkyrie.config.storage_adapter.find_by(id: page.file_ids.first)
page.file_ids = []
page = Valkyrie.config.metadata_adapter.persister.save(resource: page)
```

### Change Sets (9:30)

Wraps a resource to provide validation, dirty tracking, and data coercion.  Makes use of `reform` to power forms in the webapp.
```ruby
change_set = Valkyrie::ChangeSet.new(obj)
change_set.validate(attribute_hash)
change_set.sync
updated_resource = Valkyrie.config.metadata_adapter.persister.save(resource: obj)
```
See <https://github.com/samvera/valkyrie/wiki/ChangeSets-and-Dirty-Tracking>

#### Exercise 2: Build a change set

Edit app/models/book_change_set.rb
```ruby
class BookChangeSet < Valkyrie::ChangeSet
  property :title
  property :author
  property :series
  property :alternate_ids

  validates :title, presence: true
  validates :author, presence: true
end
```

Now let's try it out:
```ruby
book = Book.new
change_set = BookChangeSet.new(book)
change_set.changed?
change_set.valid?
change_set.errors
change_set.title = ["Tuesdays at the Castle"]
change_set.author = ["Jessica Day George"]
change_set.changed?
change_set.changed
change_set.valid?
# Our change set is valid but our book is unchanged until we call #sync
book.title
change_set.sync
book.title
# Now we can save the book resource
saved_book = Valkyrie.config.metadata_adapter.persister.save(resource: book)
```

Instead of setting individual methods on the change set we can pass a parameter hash to `#validate`:
```ruby
book = Book.new
change_set = BookChangeSet.new(book)
change_set.validate({title: ["Tuesdays at the Castle"], author: ["Jessica Day George"] })
change_set.changed
book.title
change_set.sync
saved_book = Valkyrie.config.metadata_adapter.persister.save(resource: book)
```

### Excercise: Putting it together in a controller (9:45)

First we need to add a method to the resource model in order to rendering book resources.  Let's not dwell on this.
```ruby
def to_partial_path
  "#{model_name.collection}/#{model_name.element}"
end
```

Next generate the boilerplate controller, helper, and views:
```sh
docker-compose exec app bundle exec rails g scaffold_controller Book title:string author:string series:string alternate_ids:string
```

Now let's try it in the browser: <http://localhost:3000/books>

#### Index

Try fixing the index action.  Hint: We need to gather all of the book resources from the data store so we should use the query service.
<details>
  <summary>Solution</summary>

  ```ruby
  def index
    @books = Valkyrie.config.metadata_adapter.query_service.find_all_of_model(model: Book)
  end
  ```
</details>

#### New

Now our index view should load but there isn't any books to display.  We'll need to create one so click the New book link.
We'll need to fix a couple things before this will work: the new action and the form partial.
First let's look at the controller action.  The scaffolding gives us a new book object which is great but we're going to be rendering a form so we'll need a change set.
<details>
  <summary>Solution</summary>

  ```ruby
  def new
    @book = Book.new
    @change_set = BookChangeSet.new(@book)
  end
  ```
</details>
Next we'll use the change set in the form (`app/views/books/_form.html.erb`).
Try fixing the form by using a change set.  Hint: `Valkyrie::ChangeSet.model` returns the model resource it wraps.
<details>
  <summary>Solution</summary>

  ```ruby
  <%= form_with(model: @change_set.model) do |form| %>
    <% if @change_set.errors.any? %>
      <div style="color: red">
        <h2><%= pluralize(@change_set.errors.count, "error") %> prohibited this book from being saved:</h2>

        <ul>
          <% @change_set.errors.each do |error| %>
            <li><%= error.full_message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>
  ```
</details>

#### Create

With that our new book form should render in the browser.
Fill out the form and try submitting it.
The next step for us will be changing the create action in the controller to validate the form input and persist it.  Give it a try using what we learned about change sets and persisters.
<details>
  <summary>Solution</summary>

  ```ruby
  def create
    @book = Book.new
    @change_set = BookChangeSet.new(@book)
    if @change_set.validate(book_params)
      @change_set.sync
      @book = Valkyrie.config.metadata_adapter.persister.save(resource: @book)
    end

    respond_to do |format|
      if @book.persisted?
        format.html { redirect_to book_url(@book), notice: "Book was successfully created." }
        format.json { render :show, status: :created, location: @book }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @change_set.errors, status: :unprocessable_entity }
      end
    end
  end
  ```
</details>

#### Show

We can create book objects now and see them on the index page!
Try going to the show view for a book...we'll have to change how we retrieve the book.  We can do this in the `before_action`.
<details>
  <summary>Solution</summary>

  ```ruby
  def set_book
    @book = Valkyrie.config.metadata_adapter.query_service.find_by(id: params[:id])
  end
  ```
</details>

#### Edit + Update

Now let's do the same thing for edits.  Our edit form should work since it is the same form we already fixed but we'll have to fix the edit and update actions in the controller.
Hint: Update and create aren't all that different, right?
<details>
  <summary>Solution</summary>

  ```ruby
  def edit
    @change_set = BookChangeSet.new(@book)
  end

  def update
    updated = false
    @change_set = BookChangeSet.new(@book)
    if @change_set.validate(book_params)
      @change_set.sync
      @book = Valkyrie.config.metadata_adapter.persister.save(resource: @book)
      updated = true
    end

    respond_to do |format|
      if updated
        format.html { redirect_to book_url(@book), notice: "Book was successfully updated." }
        format.json { render :show, status: :ok, location: @book }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @change_set.errors, status: :unprocessable_entity }
      end
    end
  end
  ```
</details>

#### Delete

We can create and update books so let's work on deleting books.  The persister handles deletes as well as saves.
<details>
  <summary>Solution</summary>

  ```ruby
  def destroy
    Valkyrie.config.metadata_adapter.persister.delete(resource: @book)

    respond_to do |format|
      format.html { redirect_to books_url, notice: "Book was successfully destroyed." }
      format.json { head :no_content }
    end
  end
  ```
</details>

### Wrap up (10:25)

We saw how the DataMapper pattern explodes the ActiveRecord pattern into a set of single responsibility classes.  We learned about each class and then brought it all together to make a simple rails controller.

What we didn't discuss:

#### Indexer
Creates a hash for indexing a representation of the resource in solr.  Only used by solr adapter (via `resource_indexer` kwarg)
```ruby
Indexer.new(resource: obj).to_solr
```
See <https://github.com/samvera/valkyrie/wiki/Custom-Indexing>

## Resources

  * [Dive into Valkyrie](https://github.com/samvera/valkyrie/wiki/Dive-into-Valkyrie)
  * [Valkyrie wiki](https://github.com/samvera/valkyrie/wiki)
