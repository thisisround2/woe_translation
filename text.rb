require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "hexapdf"   # <-- whatever gem you need
end

require "hexapdf"
require "json"


class ShowTextProcessor < HexaPDF::Content::Processor

  def initialize(page)
    super()
    @canvas = page.canvas(type: :overlay)
  end

    def show_text(str)
    boxes = decode_text_with_positioning(str)
    return if boxes.string.empty?

    # Combined string
    text = boxes.string

    # Bounding box of the entire text fragment
    llx, lly = *boxes.lower_left
    urx, ury = *boxes.upper_right
    width  = urx - llx
    height = ury - lly

    puts "Word: #{text.inspect} at (#{llx}, #{lly}), size (#{width}x#{height})"
    end

  alias :show_text_with_positioning :show_text

end

doc = HexaPDF::Document.open(ARGV.shift)
doc.pages.each_with_index do |page, index|
  puts "Processing page #{index + 1}"
  processor = ShowTextProcessor.new(page)
  page.process_contents(processor)
end
doc.write('show_char_boxes.pdf', optimize: true)