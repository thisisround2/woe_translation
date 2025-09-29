require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "hexapdf"   # <-- whatever gem you need
end
#!/usr/bin/env ruby
# Usage: ruby pdf_to_json.rb input.pdf > output.json
# Images will be saved to ./extracted_images/

require "hexapdf"
require "json"
require "fileutils"

class ExtractProcessor < HexaPDF::Content::Processor
  attr_reader :blocks

  def initialize(doc, page_height, img_dir)
    super()
    @doc = doc
    @page_height = page_height
    @img_dir = img_dir
    @blocks = []
    @img_index = 0
  end

  # --- TEXT ---
  def show_text(str)
    boxes = decode_text_with_positioning(str)
    return if boxes.string.empty?

    text = boxes.string
    llx, lly = *boxes.lower_left
    urx, ury = *boxes.upper_right

    visual_font_size = (ury - lly).abs
    logical_font_size = graphics_state.font_size

    @blocks << {
      type: "text",
      text: text,
      x: llx,
      y: lly,
      w: urx - llx,
      h: ury - lly,
      font_size: visual_font_size,
      pdf_font_size: logical_font_size
    }
  end
  alias :show_text_with_positioning :show_text

  # --- IMAGES ---
  def paint_xobject(name)
    xobj = resources.xobject(name)
    if xobj[:Subtype] == :Image
      @img_index += 1

      # Get transformation matrix for placement
      a, b, c, d, e, f = graphics_state.ctm.to_a

      # Image size in user space
      width  = xobj[:Width].to_f
      height = xobj[:Height].to_f

      # Transform to page coordinates
      # ctm maps unit square -> placed image
      x = e
      y = f
      w = a.abs
      h = d.abs

      # Save image to file
      filter = xobj[:Filter]
      ext =
        case filter
        when :DCTDecode then "jpg"
        when :JPXDecode then "jp2"
        when :FlateDecode, :LZWDecode, :CCITTFaxDecode then "png"
        else "bin"
        end

      img_filename = "page#{@img_index}_#{name}.#{ext}"
      img_path = File.join(@img_dir, img_filename)
      File.binwrite(img_path, xobj.stream)

      @blocks << {
        type: "image",
        name: name.to_s,
        file: img_path,
        filter: filter,
        x: x,
        y: y,
        w: w,
        h: h
      }
    else
      super
    end
  end
end

def parse_pdf(path)
  doc = HexaPDF::Document.open(path)
  pages = []

  img_dir = File.join(Dir.pwd, "extracted_images")
  FileUtils.mkdir_p(img_dir)

  doc.pages.each do |page|
    height = page.box(:media).height
    processor = ExtractProcessor.new(doc, height, img_dir)
    page.process_contents(processor)

    pages << {
      number: page.index + 1,
      width: page.box(:media).width,
      height: height,
      blocks: processor.blocks
    }
  end

  { pages: pages }
end

if ARGV.empty?
  puts "Usage: ruby #{File.basename(__FILE__)} input.pdf"
  exit 1
end

pdf_path = ARGV[0]
result = parse_pdf(pdf_path)
puts JSON.pretty_generate(result)
