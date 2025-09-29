#!/usr/bin/env ruby
# Usage: ruby json_to_pdf_working.rb input.json output.pdf

require "json"
require "hexapdf"

def num(v, default = 0.0)
  f = Float(v) rescue nil
  return default if f.nil? || f.nan? || f.infinite?
  f
end

def clamp(v, min, max)
  [[v, min].max, max].min
end

def sanitize_text(font, s)
  return "" if s.nil?
  s.to_s.each_char.map { |ch|
    begin
      font.wrapper.character_code_for(ch.ord) ? ch : "?"
    rescue
      "?"
    end
  }.join
end

input  = ARGV[0] or abort("Usage: ruby #{$PROGRAM_NAME} input.json [out.pdf]")
output = ARGV[1] || "rebuilt.pdf"

data  = JSON.parse(File.read(input), symbolize_names: true)
pages = Array(data[:pages])
abort("JSON missing :pages") if pages.empty?

doc = HexaPDF::Document.new

# Use Noto Sans as the ONLY active font (no Helvetica anywhere)
noto_path = File.expand_path("NotoSans-Regular.ttf", __dir__)
abort("❌ Missing font #{noto_path}") unless File.exist?(noto_path)
font = doc.fonts.add(noto_path, embed: true)

pages.each_with_index do |pg, idx|
  pw = num(pg[:width], 595.0);  pw = 595.0 if pw <= 0 || pw > 20000
  ph = num(pg[:height], 842.0); ph = 842.0 if ph <= 0 || ph > 20000

  canvas = doc.pages.add([0, 0, pw, ph]).canvas
  drew = false

  Array(pg[:blocks]).each do |b|
    next unless b && b[:type] == "text"

    raw = b[:text].to_s
    next if raw.strip.empty?

    x  = clamp(num(b[:x], 0.0),      0.0, pw - 2.0)
    y  = clamp(num(b[:y], ph - 20.0), 0.0, ph - 2.0)
    fs = num(b[:font_size], num(b[:h], 12.0)).abs
    fs = 1.0 if fs <= 0

    txt = sanitize_text(font, raw)
    next if txt.empty?

    canvas.font(font, size: fs)
    canvas.text(txt, at: [x, y])
    drew = true
  end

  unless drew
    canvas.font(font, size: 12)
    canvas.text("Empty page #{idx + 1}", at: [20, ph - 20])
  end
end

# Validate & write a proper PDF
doc.validate(auto_correct: true)
doc.write(output, optimize: true, validate: true)
puts "✅ Wrote: #{output} (#{File.size(output)} bytes)"
