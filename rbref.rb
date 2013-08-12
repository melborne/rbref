require "rubygems"
require "sinatra"

configure do
  VERSIONS = Dir['views/1*', 'views/2*'].map { |path| File.basename(path, '.*') }.sort
  LATEST = VERSIONS.last
end

get '/' do
  erb LATEST.to_sym
end

get '/:version' do |ver|
  erb ver.to_sym
end

