require "rack/request"
require "rack/response"

require "yaml"
require "json"
require "digest/sha1"

require "couchbase"

class Tracker
  def initialize
    # load configuration
    config = YAML.load(File.read("#{__dir__}/config.yml"))

    # establish database connection
    options = Couchbase::Cluster::ClusterOptions.new
    options.authenticate(config["username"], config["password"])
    @cluster = Couchbase::Cluster.connect(config["address"], options)
    @collection = @cluster.bucket(config["bucket"]).default_collection
  end

  def call(env)
    req = Rack::Request.new(env)

    body = {}
    case req.path
    when /\/add\/?/ # regexp with optional trailing slash
      url = req.params["url"]
      if url.nil? || url.empty?
        body["error"] = "empty_url"
      else
        id = Digest::SHA1.hexdigest(url)
        # create document if it does not exist
        options = Couchbase::Collection::MutateInOptions.new
        options.store_semantics = :upsert
        res = @collection.mutate_in(id, [
          Couchbase::MutateInSpec.upsert("url", url),     # overwrite URL
          Couchbase::MutateInSpec.increment("visits", 1)  # increment visits counter
        ], options)
        body["visits"] = res.content(1)
        body["ok"] = true
      end
    when /\/list\/?/
      res = @cluster.query("SELECT url, visits FROM #{@collection.bucket_name}")
      body["hits"] = res.rows.to_a # just convert rows to array
      body["ok"] = true
    else
      body["error"] = "invalid_action"
    end

    res = Rack::Response.new
    res.content_type = "application/json"
    res.write(JSON.generate(body))
    res.finish
  end
end
