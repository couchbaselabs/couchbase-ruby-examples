class ReviewPresenter
  def initialize(data)
    @data = data
  end

  def reviewer
    @data["reviewer"]
  end

  def date
    Time.parse(@data["date"])
  end

  def subject
    @data["subject"]
  end

  def content
    @data["content"]
  end
end

class BookPresenter
  def initialize(data)
    @data = data
  end

  def id
    @data["id"]
  end

  def url
    "/book/#{id}"
  end

  def title
    @data["title"]
  end

  def author
    [@data["authors"]["author"]].flatten.map{|a| a["name"]}.join(", ")
  end

  def image_url
    @data["image_url"]
  end

  def description
    @data["description"]
  end

  def category
    @data["category"]
  end

  def publisher
    @data["publisher"]
  end

  def isbn
    @data["isbn"]
  end

  def isbn13
    @data["isbn13"]
  end

  def year
    @data["publication_year"]
  end

  def average_rating
    @data["average_rating"]
  end

  def ratings_count
    @data["ratings_count"]
  end

  def goodreads_url
    @data["url"]
  end

  def has_reviews?
    !@data["reviews"].nil? && !@data["reviews"].empty?
  end

  def reviews
    return [] unless has_reviews?
    @data["reviews"].map { |entry| ReviewPresenter.new(entry) }
  end
end

class BookFromSearchPresenter
  def initialize(data, collection)
    @data = data
    @collection = collection
  end

  def id
    @data.id
  end

  def url
    "/book/#{id}"
  end

  def description
    highlighted("description") || document.description
  end

  def title
    highlighted("title") || document.title
  end

  def author
    highlighted("author") || document.author
  end

  def image_url
    document.image_url
  end

  def highlighted(field)
    if @data.fragments.key?(field)
      @data.fragments[field].join("...")
        .force_encoding(Encoding::UTF_8)
        .gsub(/<(em|b|i)\s*\/?>/, '')
    end
  end

  def document
    @document ||= load_document
  end

  def load_document
    options = Couchbase::Collection::GetOptions.new
    options.projections = ["description", "title", "authors", "image_url"]
    res = @collection.get(id, options)
    BookPresenter.new(res.content)
  end
end
