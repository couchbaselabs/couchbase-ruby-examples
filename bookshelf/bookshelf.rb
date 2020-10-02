require "sinatra"

require_relative "storage"
storage = Storage.new

get "/" do
  current_page = (params[:page] || 1).to_i
  @books = storage.list_books(page: current_page)
  erb :list
end

get "/book/:id" do
  @book = storage.get_book(params[:id])
  erb :show
end

post "/review" do
  storage.add_review(params[:id], params[:review])
  redirect "/book/#{params[:id]}"
end

get "/search" do
  redirect "/" if params[:query].nil? || params[:query].empty?

  current_page = (params[:page] || 1).to_i
  @books = storage.search_books(params[:query], page: current_page)
  erb :list
end

