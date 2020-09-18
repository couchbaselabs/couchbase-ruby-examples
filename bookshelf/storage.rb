require "yaml"

require "couchbase"

require_relative "presenters"

class Storage
  def initialize
    # load configuration
    config = YAML.load(File.read("#{__dir__}/config.yml"))["couchbase"]

    # establish database connection
    options = Couchbase::Cluster::ClusterOptions.new
    options.authenticate(config["username"], config["password"])
    @cluster = Couchbase::Cluster.connect(config["address"], options)
    @bucket = @cluster.bucket(config["bucket"])
    @collection = @bucket.default_collection
  end

  def add_book(book)
    @collection.upsert(book["id"], book.merge("type" => "book"))
  end

  def get_book(id)
    res = @collection.get(id)
    BookPresenter.new(res.content)
  end

  def list_books(page: 1, per_page: 10)
    options = Couchbase::Cluster::QueryOptions.new
    options.metrics = true
    offset = (page - 1) * per_page
    res = @cluster.query(<<~QUERY, options)
      SELECT * FROM `#{@bucket.name}` AS book
      ORDER BY publication_year DESC
      OFFSET #{offset}
      LIMIT #{per_page}
    QUERY
    {
      page: page,
      total_pages: res.meta_data.metrics.sort_count.to_i / per_page,
      rows: res.rows.map { |row| BookPresenter.new(row["book"]) },
    }
  end

  def add_review(id, review)
    review["date"] = Time.now.utc
    review["reviewer"] = "Anonymous" if review["reviewer"].nil? || review["reviewer"].empty?
    @collection.mutate_in(id, [
      Couchbase::MutateInSpec.array_prepend("reviews", [review]).create_path
    ])
  end

  def search_books(query, page: 1, per_page: 10)
    options = Couchbase::Cluster::SearchOptions.new
    options.skip = (page - 1) * per_page
    options.limit = per_page
    options.highlight_style = :html
    options.highlight_fields = ["title", "author", "description"]
    res = @cluster.search_query(
      "books-index", # the index definition is located in bin/create_indexes
      Couchbase::Cluster::SearchQuery.query_string(query),
      options
    )
    total_pages = 3 # should be enough for search results
    if res.meta_data.metrics.total_rows < per_page
      # but if there is no results, use current page number
      total_pages = page
    end
    {
      page: page,
      total_pages: total_pages,
      rows: res.rows.map { |row| BookFromSearchPresenter.new(row, @collection) },
    }
  end
end
