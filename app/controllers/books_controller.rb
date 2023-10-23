class BooksController < ApplicationController
  before_action :set_book, only: %i[ show edit update destroy ]

  # GET /books or /books.json
  def index
    @books = Valkyrie.config.metadata_adapter.query_service.find_all_of_model(model: Book)
  end

  # GET /books/1 or /books/1.json
  def show
  end

  # GET /books/new
  def new
    @book = Book.new
    @change_set = BookChangeSet.new(@book)
  end

  # GET /books/1/edit
  def edit
    @change_set = BookChangeSet.new(@book)
  end

  # POST /books or /books.json
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

  # PATCH/PUT /books/1 or /books/1.json
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
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @change_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1 or /books/1.json
  def destroy
    Valkyrie.config.metadata_adapter.persister.delete(resource: @book)

    respond_to do |format|
      format.html { redirect_to books_url, notice: "Book was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_book
      @book = Valkyrie.config.metadata_adapter.query_service.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def book_params
      params.require(:book).permit(:title, :author, :series, :alternate_ids)
    end
end
