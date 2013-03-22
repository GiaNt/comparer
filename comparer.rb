# encoding: utf-8
require 'bundler'
Bundler.require(:default)

module Comparer
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

    MAKERS = [
      # plaats - juweliernaam - juwelier - maker
      'Deumer Kom.-Ges. Wilhelm (Lüdenscheid)',
      'Bertsch L. (Karlsruhe)',
      'Ziemer & Söhne (Oberstei)',
      'Liefergemeinschaft Pforzheimer Innungen (Pforzhei)',
      'Zimmermann C. F. (Pforzheim)',
      'Mayer B.H. (Pforzheim)',
      'Rettenmaier Alois (Schwäbisch Gmünd)',
      'Redo Werner (Saarlautern)',
      'Reischauer Franz (Oberstein)',
      'Stubbe Afred (Berlin)',
      'Souval Rudolf (Wien VII)',
      'Glaser & Sohn (Dresden)',
      'Meybauer Paul (Berlin)',
      'Stärz R. (Gablonz)',
      'Sieper & Söhne Richard (Lüdenscheid)',
      'Scheurle Franz (Schwäbisch Gmünd)',
      'Zappe Otto (Gablonz)',
      'Hauschild R. (Pforzheim)',
      'Juncker C. E. (Berlin)',
      'Schickle Otto (Pforzheim)',
      'Förster & Barth (Pforzheim)',
      'Godet &. Co. Gebr. (Berlin)',
      'Hofstätter Ferd. (Bonn)',
      'Osang G.H. (Dresden)',
      'Noswitz A. (Gablonz a. N.)',
      'Schmidt F. (Gablonz a. N.)',
      'Miksch G. (Gablonz a. N.)',
      'Wander Heinrich (Gablonz a. N.)',
      'Klampt und Söhne (Gablonz a. N.)',
      'Simm und Söhne R. (Gablonz a. N.)',
      'Walter & Henlein (Gablonz a. N.)',
      'Hermann (Gablonz a. N.)',
      'Seiboth R. (Gablonz a. N.)',
      'Pala W. (Gablonz a. N.)',
      'Tham August G. (Gablonz)',
      'Ochs & Bonn (Hanau)',
      'Linden Friedrich (Lüdenscheid)',
      'Siegel & Söhne Richard (Lüdenscheid)',
      'Steinhauer & Lück (Lüdenscheid)',
      'Brehmer Gustav (Markneukirchen)',
      'Wurster Karl (Markneukirchen)',
      'Wächtler & Lange (Mittweida)',
      'Danner G. (Mühlhausen/Th.)',
      'Deschler & Sohn (München)',
      'Keller Friedrich (Oberstein)',
      'Richter Rudolf (Schlag)',
      'Poellath Carl (Schrobenhausen)',
      'Forster & Graf (Schwäbisch Gmünd)',
      'Türḱs Wwe. Ph. (Wien XVL)',
      'Orth Friedrich (Wien)',
      'Gnad Hans (Wien)'
    ].sort

    key :maker,        String
    key :review,       String
    key :packing,      String
    key :picture_view, String
    key :origin,       String

    timestamps!
    attachment :file

    #validates_format_of :tag_names, :with => /\A([A-Z\s\-]+,?)*\z/i
    validates_format_of :file_type, :with => %r{^image/.+}i
    #validates_numericality_of :file_size, :less_than => 524288 # 512kb

    #def self.tags
    #  fields(:tags).flat_map(&:tags).uniq
    #end

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

      if params[:maker] && !params[:maker].empty?
        @pictures = (@pictures || Picture).where(:maker => params[:maker])
      end
      if params[:review] && !params[:review].empty?
        @pictures = (@pictures || Picture).where(:review => params[:review])
      end
      if params[:packing] && !params[:packing].empty?
        @pictures = (@pictures || Picture).where(:packing => params[:packing])
      end
      if params[:picture_view] && !params[:picture_view].empty?
        @pictures = (@pictures || Picture).where(:picture_view => params[:picture_view])
      end
      if params[:origin] && !params[:origin].empty?
        @pictures = (@pictures || Picture).where(:origin => params[:origin])
      end

      haml :compare
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
      picture.maker = params[:maker]
      picture.review = params[:review]
      picture.packing = params[:packing]
      picture.picture_view = params[:picture_view]
      picture.origin = params[:origin]

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
