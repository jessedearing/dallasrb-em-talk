require 'sinatra'
require 'haml'

set :views, settings.root
set :public_folder, settings.root
get('/') { haml :index, format: :html5 }
