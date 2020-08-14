require "sinatra"
require "sinatra/json"

require "yaml"
require "json"
require "digest/sha1"

require "couchbase"

class Storage
  def self.instance
    @instance ||= Storage.new
  end

  def initialize
    # load configuration
    config = YAML.load(File.read("#{__dir__}/config.yml"))

    # establish database connection
    options = Couchbase::Cluster::ClusterOptions.new
    options.authenticate(config["username"], config["password"])
    @cluster = Couchbase::Cluster.connect(config["address"], options)
    @collection = @cluster.bucket(config["bucket"]).default_collection
  end

  def add_url(url)
    id = Digest::SHA1.hexdigest(url)
    # create document if it does not exist
    options = Couchbase::Collection::MutateInOptions.new
    options.store_semantics = :upsert
    res = @collection.mutate_in(id, [
      Couchbase::MutateInSpec.upsert("url", url),     # overwrite URL
      Couchbase::MutateInSpec.increment("visits", 1)  # increment visits counter
    ], options)
    # return current counter
    res.content(1)
  end

  def list_urls
    res = @cluster.query("SELECT url, visits FROM #{@collection.bucket_name}")
    res.rows.to_a # just convert rows to array
  end
end

# more info about sinatra
#
# http://sinatrarb.com/intro.html

get "/add" do
  url = params["url"]
  if url.nil? || url.empty?
    json "error" => "empty_url"
  else
    begin
      counter = Storage.instance.add_url(url)
      json "ok" => true, "visits" => counter
    rescue => ex
      json "error" => ex.to_s
    end
  end
end

get "/list" do
  begin
    urls = Storage.instance.list_urls
    json "ok" => true, "hits" => urls
  rescue => ex
    json "error" => ex.to_s
  end
end
