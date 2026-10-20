require "vips"

# Pango on macOS defaults to CoreText, which ignores bundled font files; Linux
# already uses fontconfig. Must be set before the first text render.
ENV["PANGOCAIRO_BACKEND"] ||= "fc"

# Renders the 1200×630 card chat apps show when an invite link is shared
# (og:image): the event name and date over artwork matching its page.
# Map a slug to a theme in THEMES to give a custom page a matching card;
# every other event gets the :classic card.
class EventPreviewImage
  WIDTH = 1200
  HEIGHT = 630
  VERSION = 1 # bump after changing the artwork so cached cards re-render
  THEMES = { "eitan" => :night, "lev" => :shield }.freeze

  # Static instances from Google Fonts (SIL Open Font License), in vendor/fonts.
  FONT_FILES = {
    "Fredoka Bold" => "Fredoka-Bold.ttf",
    "Fredoka SemiBold" => "Fredoka-SemiBold.ttf",
    "Cormorant Garamond SemiBold" => "CormorantGaramond-SemiBold.ttf",
    "Inter Medium" => "Inter-Medium.ttf"
  }.freeze

  def initialize(event)
    @event = event
    @theme = THEMES.fetch(event.slug, :classic)
  end

  def version = "#{VERSION}.#{@event.updated_at.to_i}"
  def cache_key = [ "event-preview", VERSION, @event.cache_key_with_version ]

  def to_jpeg
    canvas = svg(send(:"#{@theme}_background"))
    stack(canvas, send(:"#{@theme}_layers"), center_y: send(:"#{@theme}_center_y"))
      .flatten.jpegsave_buffer(Q: 90, optimize_coding: true)
  end

  private

  def when_text = ApplicationController.helpers.event_when(@event)

  # --- Night sky (Eitan's sleepunder) ---------------------------------------

  def night_center_y = 272

  def night_layers
    [
      [ text("YOU'RE INVITED TO", font: "Fredoka SemiBold", size: 24, color: "#8be9d4", tracking: 6), 0 ],
      [ fit(@event.name, font: "Fredoka Bold", sizes: [ 92, 82, 72, 62 ], max_height: 240, color: "#ffffff", line_height: 0.98), 18 ],
      [ pill(text(when_text, font: "Fredoka SemiBold", size: 36, color: "#ffe28a")), 30 ]
    ]
  end

  def night_background
    rng = Random.new(7)
    stars = Array.new(120) do
      %(<circle cx="#{rng.rand(WIDTH)}" cy="#{rng.rand(HEIGHT - 60)}" r="#{(0.6 + rng.rand * 1.6).round(2)}" fill="#fff7d6" fill-opacity="#{(0.3 + rng.rand * 0.7).round(2)}"/>)
    end
    sparkles = [ [ 120, 90, 16 ], [ 170, 215, 9 ], [ 1110, 300, 12 ], [ 700, 36, 8 ], [ 70, 330, 10 ], [ 1000, 420, 9 ], [ 330, 60, 7 ] ]
      .map { |x, y, s| sparkle(x, y, s) }
    zzz = [ [ 936, 92, 13 ], [ 896, 60, 18 ], [ 850, 24, 23 ] ].map { |x, y, s| %(<path d="M#{x} #{y}h#{s}l-#{s} #{s}h#{s}"/>) }

    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{WIDTH}" height="#{HEIGHT}">
        <defs>
          <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="#0a1230"/><stop offset=".5" stop-color="#0f1b3d"/><stop offset="1" stop-color="#1d2b64"/>
          </linearGradient>
          #{radial("moonglow", "#ffe28a", 0.4)}
          #{radial("pink", "#ff8fab", 0.22)}
          #{radial("mint", "#8be9d4", 0.12)}
          #{radial("violet", "#7c6cf0", 0.28)}
          <mask id="crescent">
            <rect width="#{WIDTH}" height="#{HEIGHT}" fill="#fff"/>
            <circle cx="1012" cy="98" r="58" fill="#000"/>
          </mask>
        </defs>
        <rect width="#{WIDTH}" height="#{HEIGHT}" fill="url(#sky)"/>
        <circle cx="140" cy="600" r="420" fill="url(#pink)"/>
        <circle cx="60" cy="40" r="320" fill="url(#mint)"/>
        <circle cx="820" cy="640" r="460" fill="url(#violet)"/>
        #{stars.join}
        <g fill="#fff7d6">#{sparkles.join}</g>
        <circle cx="1040" cy="120" r="200" fill="url(#moonglow)"/>
        <circle cx="1040" cy="120" r="64" fill="#ffe28a" mask="url(#crescent)"/>
        <g fill="none" stroke="#fff7d6" stroke-opacity=".75" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">#{zzz.join}</g>
        <g opacity=".9" fill="#26336f">#{[ -40, 230, 520, 800, 1080, 1300 ].map { |x| cloud(x, 585, 1.15) }.join}</g>
        <g opacity=".95" fill="#2f3e82">#{[ 90, 380, 660, 950, 1220 ].map { |x| cloud(x, 628, 1.0) }.join}</g>
      </svg>
    SVG
  end

  def sparkle(x, y, s)
    k = (s * 0.22).round(1)
    %(<path d="M#{x} #{y - s}Q#{x + k} #{y - k} #{x + s} #{y}Q#{x + k} #{y + k} #{x} #{y + s}Q#{x - k} #{y + k} #{x - s} #{y}Q#{x - k} #{y - k} #{x} #{y - s}Z"/>)
  end

  def cloud(x, y, scale)
    [ [ -95, 12, 44 ], [ -45, -14, 58 ], [ 18, -30, 68 ], [ 82, -8, 52 ], [ 128, 14, 40 ] ]
      .map { |dx, dy, r| %(<circle cx="#{x + dx * scale}" cy="#{y + dy * scale}" r="#{r * scale}"/>) }.join
  end

  # Frosted rounded badge behind a line of text, like the badges on the page.
  def pill(content, pad_x: 34, pad_y: 14)
    w = content.width + pad_x * 2
    h = content.height + pad_y * 2
    svg(<<~SVG).composite(content, :over, x: pad_x, y: pad_y)
      <svg xmlns="http://www.w3.org/2000/svg" width="#{w}" height="#{h}">
        <rect x="1.5" y="1.5" width="#{w - 3}" height="#{h - 3}" rx="#{(h - 3) / 2.0}" fill="#ffffff" fill-opacity=".1" stroke="#ffffff" stroke-opacity=".3" stroke-width="2"/>
      </svg>
    SVG
  end

  # --- Star shield (Lev's Captain America party) ----------------------------

  def shield_center_y = 330

  def shield_layers
    [
      [ text("TOP SECRET MISSION", font: "Fredoka SemiBold", size: 24, color: "#ffd166", tracking: 6), 0 ],
      [ fit(@event.name, font: "Fredoka Bold", sizes: [ 88, 78, 68, 60 ], max_height: 220, color: "#ffffff", line_height: 0.98), 16 ],
      [ pill(text(when_text, font: "Fredoka SemiBold", size: 34, color: "#ffffff")), 28 ]
    ]
  end

  def shield_background
    rng = Random.new(11)
    stars = Array.new(40) do
      x, y = rng.rand(WIDTH), rng.rand(HEIGHT)
      x, y = rng.rand(WIDTH), rng.rand(HEIGHT) while (240..960).cover?(x) && (20..510).cover?(y) # keep the text clear
      star_path(x, y, (5 + rng.rand * 9).round(1), fill: %w[#ffffff #ffffff #ff6b7d #ffd166].sample(random: rng), opacity: (0.25 + rng.rand * 0.6).round(2))
    end
    stripes = (0..12).map { |i| %(<rect x="0" y="#{i * 48}" width="#{WIDTH}" height="24" fill="#d7263d"/>) }

    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{WIDTH}" height="#{HEIGHT}">
        <defs>
          <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="#08153b"/><stop offset=".55" stop-color="#0b1d4f"/><stop offset="1" stop-color="#14307a"/>
          </linearGradient>
          #{radial("glow", "#3d63d6", 0.45)}
          #{radial("redglow", "#d7263d", 0.3)}
        </defs>
        <rect width="#{WIDTH}" height="#{HEIGHT}" fill="url(#bg)"/>
        <g opacity=".07">#{stripes.join}</g>
        <circle cx="600" cy="300" r="520" fill="url(#glow)"/>
        <circle cx="1120" cy="620" r="360" fill="url(#redglow)"/>
        #{stars.join}
        <g transform="translate(600 92)">
          <circle r="62" fill="#d7263d"/><circle r="49" fill="#f4f6fb"/><circle r="36" fill="#d7263d"/><circle r="25" fill="#14307a"/>
          #{star_path(0, 0, 22, fill: "#ffffff")}
        </g>
      </svg>
    SVG
  end

  def star_path(cx, cy, r, fill:, opacity: 1)
    points = (0...10).map do |i|
      radius = i.even? ? r : r * 0.4
      angle = (-90 + 36 * i) * Math::PI / 180
      "#{(cx + radius * Math.cos(angle)).round(1)},#{(cy + radius * Math.sin(angle)).round(1)}"
    end
    %(<polygon points="#{points.join(" ")}" fill="#{fill}" fill-opacity="#{opacity}"/>)
  end

  # --- Classic (every other event) ------------------------------------------

  def classic_center_y = HEIGHT / 2

  def classic_layers
    [
      [ text("YOU'RE INVITED TO", font: "Inter Medium", size: 20, color: "#1c1c1c", alpha: 55, tracking: 6), 0 ],
      [ fit(@event.name, font: "Cormorant Garamond SemiBold", sizes: [ 108, 96, 84, 72 ], max_height: 250, color: "#1c1c1c", line_height: 0.95), 14 ],
      [ ornament, 22 ],
      [ text(when_text, font: "Inter Medium", size: 28, color: "#1c1c1c", alpha: 80), 24 ]
    ]
  end

  def classic_background
    leaves = [ [ 26, 17, -18 ], [ 46, 32, 72 ], [ 70, 45, -8 ], [ 94, 57, 82 ], [ 120, 68, 8 ], [ 150, 78, 20 ] ]
      .map { |x, y, a| %(<path transform="translate(#{x} #{y}) rotate(#{a})" d="M0 0C9-11 25-11 34 0C25 11 9 11 0 0Z"/>) }
    rng = Random.new(3)
    confetti = Array.new(26) do
      x, y = [ [ rng.rand(60..330), rng.rand(60..230) ], [ rng.rand(870..1140), rng.rand(400..570) ] ].sample(random: rng)
      %(<circle cx="#{x}" cy="#{y}" r="#{rng.rand(2.0..4.5).round(1)}" fill="#{%w[#e8b4b8 #9bb39b #c8b48a].sample(random: rng)}" fill-opacity=".7"/>)
    end

    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{WIDTH}" height="#{HEIGHT}">
        <defs>
          #{radial("light", "#ffffff", 0.85)}
          <g id="sprig">
            <path d="M0 0C40 28 85 58 158 80" fill="none" stroke="#8fa98f" stroke-width="2.5" stroke-linecap="round"/>
            <g fill="#9bb39b">#{leaves.join}</g>
          </g>
        </defs>
        <rect width="#{WIDTH}" height="#{HEIGHT}" fill="#f3eee4"/>
        <ellipse cx="600" cy="315" rx="620" ry="380" fill="url(#light)"/>
        #{confetti.join}
        <rect x="28" y="28" width="1144" height="574" rx="6" fill="none" stroke="#c8b48a" stroke-width="2"/>
        <rect x="40" y="40" width="1120" height="550" rx="3" fill="none" stroke="#c8b48a" stroke-opacity=".5"/>
        <use href="#sprig" transform="translate(62 62)"/>
        <use href="#sprig" transform="translate(1138 568) rotate(180)"/>
      </svg>
    SVG
  end

  # Thin rule with a diamond in the middle.
  def ornament
    svg(<<~SVG)
      <svg xmlns="http://www.w3.org/2000/svg" width="240" height="16">
        <path d="M0 8H100M140 8H240" stroke="#c8b48a" stroke-width="1.5"/>
        <path d="M120 1L127 8L120 15L113 8Z" fill="#c8b48a"/>
      </svg>
    SVG
  end

  # --- Drawing helpers --------------------------------------------------------

  def radial(id, color, opacity)
    %(<radialGradient id="#{id}"><stop offset="0" stop-color="#{color}" stop-opacity="#{opacity}"/><stop offset="1" stop-color="#{color}" stop-opacity="0"/></radialGradient>)
  end

  SVG_LOADER = Mutex.new

  # Active Storage blocks libvips's SVG loader, which isn't hardened against
  # hostile files. These SVGs are all generated above (no user input), so the
  # loader is unblocked just while building one.
  def svg(source)
    SVG_LOADER.synchronize do
      Vips.block("VipsForeignLoadSvg", false)
      Vips::Image.svgload_buffer(source)
    ensure
      Vips.block("VipsForeignLoadSvg", true)
    end
  end

  # Centered, word-wrapped text as an RGBA image. tracking is letter spacing in px.
  def text(content, font:, size:, color:, alpha: 100, tracking: 0, line_height: nil)
    attrs = { foreground: color, fgalpha: "#{alpha}%", letter_spacing: tracking * 1024, line_height: line_height }.compact
    markup = "<span #{attrs.map { |k, v| %(#{k}="#{v}") }.join(" ")}>#{ERB::Util.html_escape(content.tr("'", "’"))}</span>"
    Vips::Image.text(markup, font: "#{font} #{size}", fontfile: Rails.root.join("vendor/fonts", FONT_FILES.fetch(font)).to_s,
      width: WIDTH - 240, align: :centre, wrap: :word, rgba: true)
  end

  # The largest size at which the text fits in max_height (long names wrap and shrink).
  def fit(content, sizes:, max_height:, **options)
    images = sizes.lazy.map { |size| text(content, size: size, **options) }
    images.find { |image| image.height <= max_height } || images.to_a.last
  end

  # Composites [image, gap_above] layers top to bottom, each centered
  # horizontally, the whole block centered vertically on center_y.
  def stack(canvas, layers, center_y:)
    y = center_y - layers.sum { |image, gap| image.height + gap } / 2
    positions = layers.map do |image, gap|
      y += gap
      [ (WIDTH - image.width) / 2, y ].tap { y += image.height }
    end
    canvas.composite(layers.map(&:first), :over, x: positions.map(&:first), y: positions.map(&:last))
  end
end
