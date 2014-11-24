require 'json'
require 'mechanize'
require 'open-uri'


# Public : clase para las notas de los diarios.
#
# Examples
#
#   art = Articulo.new('La Nación', 'Las Vegas', 'En las vegas hay casinos',
#                       'Carlos', '20 de agosto de 1999')
class Articulo
  # Variable de clase para contar cantidad de articulos
  @@cant_articulos

  # Public: serializa objecto a json.
  #
  #
  # Examples
  #
  #  articulo.to_json
  #
  # returns {"@autor": "carlos", ...}
  def to_json
    hash = {}
    # Dropeo el primero elemento, no quiero scrapearlo
    # es @page
    self.instance_variables.drop(1).each do |var|
      hash[var] = self.instance_variable_get var
    end
    # puts hash
    hash.to_json
  end

  # Internal: inicializa articulo.
  #
  # argument - page: website del art, diario: diario del art
  #
  # Examples
  #
  #  art.Articulo.new('www.lanacion.com/art1', 'La nacion')
  #
  def initialize page, diario
    @page = page
    @uri = page.uri
    @diario = diario
  end

  def show
    puts "Diario #{@diario}, Título #{@titulo}, Cuerpo #{@cuerpo},
          Autor: #{@autor}, Fecha: #{@fecha}"
  end

  # Public: scrapea articulo.
  #
  # argument - argument description
  #
  # Examples
  #
  #  art.scrap => setea variables de instancia titulo, cuerpo, etc
  #
  #
  def scrap
    @titulo = self.titulo
    @cuerpo = self.cuerpo
    @autor = self.autor
    @fecha = self.fecha
  end
end

class Scrapper
  def initialize d, m, a
    @d = d
    @d_s = self.to_s @d
    @m = m
    @m_s = self.to_s @m
    @a = a
    @a_s = self.to_s @a
  end

  def to_s n
    if n < 10
      '0'+n.to_s
    else
      n.to_s
    end
  end

  def avanzar
    @d+=1
    if @d == 32
      @d = 1
      @m+=1
    end

    if @m == 12
      @m = 1
      @a+=1
    end

    @d_s = self.to_s @d
    @d_m = self.to_s @m
    @d_a = self.to_s @a
  end

  def scrap
    puts "TODO: Estoy recorriendo solo el primer 'Ver mas' de cada fecha"
    # lista de proxys http://www.ip-adress.com/proxy_list/

    mechanize = Mechanize.new
    mechanize.set_proxy('58.96.182.222', 8080)
    mechanize.user_agent_alias = "Windows Mozilla"

    while @a < 2015 do
      # para recorrer articulos de la nación tengo que respetar
      # el siguiente formato:
      # http://servicios.lanacion.com.ar/archivo-f25/03/2001
      # f25: es el día, 03: mes, 2001: año.
      # Va desde diciembre 1995 hasta hoy día.
      # Para ver las notas de las diferentes secciones tengo que
      # clickear "ver mas" <a href="/archivo-f02/01/1996-c1">Ver más</a>

      # Arranco en en enero 1996
      link = "http://servicios.lanacion.com.ar/archivo-f#{@d_s}/#{@m_s}/#{@a_s}"
      puts link
      # fd con d de 01 a 31
      # m con m de 01 a 12
      # a de 1996 a 2014
      main_page = mechanize.get(link)


      links = main_page.links_with(:text => 'Ver más')
      puts link
      if !links.empty?
        # output = File.new("lnol-f#{@d_s}/#{@m_s}/#{@a_s}.json", "w+")
        output = File.new "lnol-f#{@d_s}-#{@m_s}-#{@a_s}.json", "w"
        links.each do |link|
          section_page = link.click
          # Una vez que entré en la sección puedo ver uno por uno
          # los articulos
          art_links = section_page.search('.acumulados h3 a')
          puts art_links.size
          art_links.each do |art_link|
            art_page = mechanize.click mechanize.get(art_link["href"])
            puts art_page.uri
            # Creo un objeto para la clase art_{diario} y scrapeo
            art = ArtNacion.new(art_page, 'La Nacion')
            art.scrap
            output.puts art.to_json
          end
        end
        output.close
      end
      #avanza al próximo articulo
      self.avanzar
    end
  end
end

# Public: subclase para articulos de la nacion.
class ArtNacion < Articulo
  def titulo
    @page.at('h1').text.strip
  end

  def cuerpo
    @page.at('#cuerpo').text.strip
  end

  def autor
    autor = @page.at('.firma').text.strip.split(/\W+/)
    if autor.size == 0
      "Sin autor"
    else
      autor = autor.first autor.size - 2
      autor = autor.drop(1).join(' ').to_s
    end
  end

  def fecha
    @page.at('.fecha').text.strip.split('|')[0]
  end
end

crawler = Scrapper.new 2, 1, 1996
crawler.scrap
