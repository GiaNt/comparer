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
      'Lüdenscheid - Deumer Kom.-Ges. - Wilhelm - Deumer Kom.-Ges. Wilhelm (Lüdenscheid)',
      'Karlsruhe - Bertsch - L. - Bertsch L. (Karlsruhe)',
      'Oberstein - Ziemer & Söhne - / - Ziemer & Söhne (Oberstei)',
      'Pforzheim - Liefergemeinschaft Pforzheimer Innungen - / - Liefergemeinschaft Pforzheimer Innungen (Pforzhei)',
      'Pforzheim - Zimmermann - C.F. - Zimmermann C. F. (Pforzheim)',
      'Pforzheim - Mayer - B.H. - Mayer B.H. (Pforzheim)',
      'Schwäbisch Gmünd - Rettenmaier - Alois - Rettenmaier Alois (Schwäbisch Gmünd)',
      'Saarlautern - Redo - Werner - Redo Werner (Saarlautern)',
      'Oberstein - Reischauer - Franz - Reischauer Franz (Oberstein)',
      'Berlin - Stubbe - Afred - Stubbe Afred (Berlin)',
      'Wien VII - Souval - Rudolf - Souval Rudolf (Wien VII)',
      'Dresden - Glaser & Sohn - / - Glaser & Sohn (Dresden)',
      'Berlin - Meybauer - Paul - Meybauer Paul (Berlin)',
      'Gablonz - Stärz - R. - Stärz R. (Gablonz)',
      'Lüdenscheid - Sieper & Söhne - Richard - Sieper & Söhne Richard (Lüdenscheid)',
      'Schwäbisch Gmünd - Scheurle - Franz - Scheurle Franz (Schwäbisch Gmünd)',
      'Gablonz - Zappe - Otto - Zappe Otto (Gablonz)',
      'Pforzheim - Hauschild - R. - Hauschild R. (Pforzheim)',
      'Berlin - Juncker - C. E. - Juncker C. E. (Berlin)',
      'Pforzheim - Schickle - Otto - Schickle Otto (Pforzheim)',
      'Pforzheim - Förster & Barth - / - Förster & Barth (Pforzheim)',
      'Berlin - Godet &. Co. - Gebr. - Godet &. Co. Gebr. (Berlin)',
      'Bonn - Hofstätter - Ferd. - Hofstätter Ferd. (Bonn)',
      'Dresden - Osang - G.H. - Osang G.H. (Dresden)',
      'Gablonz a. N. - Noswitz - A. - Noswitz A. (Gablonz a. N.)',
      'Gablonz a. N. - Schmidt - F. - Schmidt F. (Gablonz a. N.)',
      'Gablonz a. N. - Miksch - G. - Miksch G. (Gablonz a. N.)',
      'Gablonz a. N. - Wander - Heinrich - Wander Heinrich (Gablonz a. N.)',
      'Gablonz a. N. - Klampt und Söhne - / - Klampt und Söhne (Gablonz a. N.)',
      'Gablonz a. N. - Simm und Söhne - R. - Simm und Söhne R. (Gablonz a. N.)',
      'Gablonz a. N. - Walter & Henlein - / - Walter & Henlein (Gablonz a. N.)',
      'Gablonz a. N. - Hermann - / - Hermann (Gablonz a. N.)',
      'Gablonz a. N. - Seiboth - R. - Seiboth R. (Gablonz a. N.)',
      'Gablonz a. N. - Pala - W. - Pala W. (Gablonz a. N.)',
      'Gablonz - Tham - August G. - Tham August G. (Gablonz)',
      'Hanau - Ochs & Bonn - / - Ochs & Bonn (Hanau)',
      'Lüdenscheid - Linden - Friedrich - Linden Friedrich (Lüdenscheid)',
      'Lüdenscheid - Siegel & Söhne - Richard - Siegel & Söhne Richard (Lüdenscheid)',
      'Lüdenscheid - Steinhauer & Lück - / - Steinhauer & Lück (Lüdenscheid)',
      'Markneukirchen - Brehmer - Gustav - Brehmer Gustav (Markneukirchen)',
      'Markneukirchen - Wurster - Karl - Wurster Karl (Markneukirchen)',
      'Mittweida - Wächtler & Lange - / - Wächtler & Lange (Mittweida)',
      'Mühlhausen/Th. - Danner - G. - Danner G. (Mühlhausen/Th.)',
      'München - Deschler & Sohn - / - Deschler & Sohn (München)',
      'Oberstein - Keller - Friedrich - Keller Friedrich (Oberstein)',
      'Schlag - Richter - Rudolf - Richter Rudolf (Schlag)',
      'Schrobenhausen - Poellath - Carl - Poellath Carl (Schrobenhausen)',
      'Schwäbisch Gmünd - Forster & Graf - / - Forster & Graf (Schwäbisch Gmünd)',
      'Wien XVL - Türḱs Wwe. - Ph. - Türḱs Wwe. Ph. (Wien XVL)',
      'Wien - Orth - Friedrich - Orth Friedrich (Wien)',
      'Wien - Gnad - Hans - Gnad Hans (Wien)'
    ]

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
