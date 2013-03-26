require 'bundler'
Bundler.require(:default)

module Comparer
  PASSWORD = 'azerty'

  def self.app(db)
    MongoMapper.database = db
    App
  end

  def self.clear_db!
    Picture.all.each &:destroy
  end

  class Picture
    include MongoMapper::Document
    plugin Joint

    #key :tags, Array, typecast: 'String'
    key :award,    String
    key :view,     String
    key :review,   String
    key :maker,    String
    key :material, String
    key :reverse,  String

    timestamps!
    attachment :file

    #validates_format_of :tag_names, :with => /\A([A-Z\s\-]+,?)*\z/i
    validates_format_of :file_type, :with => %r{^image/.+}i
    #validates_numericality_of :file_size, :less_than => 524288 # 512kb

    #def self.tags
    #  fields(:tags).flat_map(&:tags).uniq
    #end

    def self.awards
      fields(:award).map(&:award).uniq.compact
    end

    def self.makers
      fields(:maker).map(&:maker).uniq.compact
    end

    def self.materials
      fields(:material).map(&:material).uniq.compact
    end

    #def tag_names=(given_tags)
    #  self.tags = given_tags.split(/,\s*/).map(&:downcase)
    #end

    #def tag_names
    #  tags.join(', ')
    #end
  end

  class App < Sinatra::Base
    set :app_file, __FILE__
    set :run, Proc.new { false }

    get '/compare' do
      title 'Compare Pictures'

      if params[:award] && !params[:award].empty?
        @pictures = (@pictures || Picture).where(:award => params[:award])
      end
      if params[:review] && !params[:review].empty?
        @pictures = (@pictures || Picture).where(:review => params[:review])
      end
      if params[:maker] && !params[:maker].empty?
        @pictures = (@pictures || Picture).where(:maker => params[:maker])
      end
      if params[:material] && !params[:material].empty?
        @pictures = (@pictures || Picture).where(:material => params[:material])
      end
      if params[:reverse] && !params[:reverse].empty?
        @pictures = (@pictures || Picture).where(:reverse => params[:reverse])
      end

      haml :compare
    end

    get '/compare_all' do
      title 'Compare All'

      if params[:award] && !params[:award].empty?
        @pictures = (@pictures || Picture).where(:award => params[:award])
      end
      if params[:review] && !params[:review].empty?
        @pictures = (@pictures || Picture).where(:review => params[:review])
      end
      if params[:maker] && !params[:maker].empty?
        @pictures = (@pictures || Picture).where(:maker => params[:maker])
      end
      if params[:material] && !params[:material].empty?
        @pictures = (@pictures || Picture).where(:material => params[:material])
      end
      if params[:reverse] && !params[:reverse].empty?
        @pictures = (@pictures || Picture).where(:reverse => params[:reverse])
      end

      haml :compare_all
    end

    get '/upload' do
      title 'Upload New Picture'

      haml :upload
    end

    post '/upload' do
      picture = Picture.new
      picture.file = params[:picture][:tempfile]
      picture.file_name = params[:picture][:filename]
      #picture.tag_names = params[:tags]
      picture.award = params[:award]
      picture.review = params[:review]
      picture.maker = params[:maker]
      picture.material = params[:material]

      haml :upload and return unless picture.save

      redirect '/compare'
    end

    get '/pictures/:id/delete' do
      title 'Remove a picture'

      haml :delete
    end

    post '/pictures/delete' do
      if params[:password] == PASSWORD
        picture = Picture.find!(params[:picture_id])
        picture.destroy
      end

      redirect '/pictures'
    end

    get '/pictures/:id' do
      picture = Picture.find!(params[:id])

      content_type picture.file.type
      picture.file.read
    end

    get '/pictures' do
      title 'Picture List'
      @pictures = Picture.sort(:file_name).all

      haml :list
    end

    get '/*' do
      redirect '/compare'
    end

  private

    def title(new_title = nil)
      @title = new_title.to_s if new_title
      @title
    end
  end
end
