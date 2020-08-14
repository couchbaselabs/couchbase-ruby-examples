# frozen_string_literal: true

# run web application
require_relative "tracker"
use Rack::ShowExceptions
run Tracker.new
