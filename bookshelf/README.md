# Example of using Couchbase with Sinatra

* Make sure Couchbase Server is running, and check `config.yml` for credentials.
  There is an configuration example in `config.yml.example`.

* Install dependencies

      ./bin/setup

* Create query and search indexes

      ./bin/create_indexes

* Import some data into the bucket. Note that this step requires internet connection
  and might take some time (about 5 minutes). The script is using goodreads.com, and
  it expects API keys provided through `config.yml`. To obtain the keys, visit
  https://www.goodreads.com/api/keys.

      ./bin/import

* Run the application

      ./bin/server

* Open `http://localhost:3000` in your browser
