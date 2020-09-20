#!/usr/bin/env ruby

require "yaml"
require "couchbase"

config = YAML.load(File.read("#{__dir__}/../config.yml"))["couchbase"]

options = Couchbase::Cluster::ClusterOptions.new
options.authenticate(config["username"], config["password"])
cluster = Couchbase::Cluster.connect(config["address"], options)

options = Couchbase::Management::QueryIndexManager::CreatePrimaryIndexOptions.new
options.ignore_if_exists = true
cluster.query_indexes.create_primary_index(config["bucket"], options)

cluster.search_indexes.drop_index("books-index")
index = Couchbase::Management::SearchIndex.new
index.type = "fulltext-index"
index.name = "books-index"
index.source_type = "couchbase"
index.source_name = config["bucket"]
index.params = {
  mapping: {
    default_mapping: {enabled: false},
    types: {
      "book" => {
        properties: {
          "title" => {
            fields: [
              {
                name: "title",
                type: "text",
                include_in_all: true,
                include_term_vectors: true,
                index: true,
                store: true,
                docvalues: true,
              },
            ],
          },
          "author" => {
            fields: [
              {
                name: "author",
                type: "text",
                include_in_all: true,
                include_term_vectors: true,
                index: true,
                store: true,
                docvalues: true,
              },
            ],
          },
          "description" => {
            fields: [
              {
                name: "description",
                type: "text",
                include_in_all: true,
                include_term_vectors: true,
                index: true,
                store: true,
                docvalues: true,
              },
            ],
          },
        },
      },
    },
  },
}
cluster.search_indexes.upsert_index(index)
