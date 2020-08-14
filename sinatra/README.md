# Example of using Couchbase with Sinatra

* Install dependencies

      ./bin/setup

* Update configuration in `config.yml` and make sure that the bucket has primary index created.

* Run the application

      ./bin/run

## The application responds to two routes

* `/add` adds URL to the database and increments counter if it is there already

      $ curl localhost:3000/add?url=http://example.com
      {"visits":1,"ok":true}

* `/list` displays known URLs

      $ curl localhost:3000/list
      {"hits":[{"url":"http://example.com","visits":1}],"ok":true}
