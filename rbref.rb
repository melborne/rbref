require "sinatra"
require "erb"
require "haml"
require "sass"

configure do
  VERSIONS = Dir['views/1*'].map { |path| File.basename(path, '.*') }.sort
  LATEST = VERSIONS.last
end

get '/' do
  erb LATEST.to_sym
end

get '/:version' do |ver|
  erb ver.to_sym
end

#get '/style.css' do
#  content_type 'text/css', :charset => 'utf-8'
#  css :style
#end
