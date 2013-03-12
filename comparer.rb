require 'bundler'
Bundler.require(:default)

module Comparer
  def self.app(db)
    MongoMapper.database = db
    App
  end

  class Picture
    include MongoMapper::Document
    plugin Joint

    key :tags, Array, typecast: 'String'
    timestamps!
    attachment :file

    validates_format_of :tag_names, :with => /\A([A-Z\s\-]+,?)*\z/i
    #validates_numericality_of :file_size, :less_than => 524288 # 512kb

    def self.tags
      fields(:tags).flat_map(&:tags).uniq
    end

    def tag_names=(given_tags)
      self.tags = given_tags.split(/,\s*/).map(&:downcase)
    end

    def tag_names
      tags.join(', ')
    end
  end

  class App < Sinatra::Base
    set :app_file, __FILE__

    get '/compare' do
      title 'Vergelijk Afbeeldingen'

      if params[:tag] && !params[:tag].empty?
        @pictures = Picture.where(tags: params[:tag]).sort(:created_at.desc)
      end

      haml :compare
    end

    get '/upload' do
      title 'Upload Nieuwe Afbeelding(en)'

      haml :upload
    end

    post '/upload' do
      picture = Picture.new
      picture.file = params[:picture][:tempfile]
      picture.file_name = params[:picture][:filename]
      picture.tag_names = params[:tags]

      haml :upload and return unless picture.save

      redirect '/compare'
    end

    get '/pictures/:id' do |name|
      picture = Picture.find!(params[:id])

      content_type picture.file.type
      picture.file.read
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
