require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "hexapdf"   # <-- whatever gem you need
end

#!/usr/bin/env ruby
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

def dims(pg)
  w = num(pg[:width], 595.0);  w = 595.0 if w <= 0 || w > 20000
  h = num(pg[:height], 842.0); h = 842.0 if h <= 0 || h > 20000
  [w, h]
end

input  = ARGV[0] or abort("Usage: ruby #{$PROGRAM_NAME} input.json [out.pdf]")
output = ARGV[1] || "rebuilt.pdf"

data  = JSON.parse(File.read(input), symbolize_names: true)
pages = Array(data[:pages])
abort("JSON missing :pages") if pages.empty?

doc = HexaPDF::Document.new

# Try NotoSans-Regular.ttf next to script; fallback to Helvetica if missing
font = nil
begin
  ttf = File.expand_path("NotoSans-Regular.ttf", __dir__)
  if File.exist?(ttf)
    font = doc.fonts.add(ttf, embed: true)
  else
    font = doc.fonts.add("Helvetica") # built-in core font
  end
rescue
  font = doc.fonts.add("Helvetica")
end

pages.each_with_index do |pg, idx|
  pw, ph = dims(pg)
  canvas = doc.pages.add([0, 0, pw, ph]).canvas

  drew = false
  Array(pg[:blocks]).each do |b|
    next unless b && b[:type] == "text"
    raw = b[:text].to_s
    next if raw.strip.empty?

    x  = clamp(num(b[:x], 0.0), 0.0, pw - 2.0)
    y  = clamp(num(b[:y], ph - 20.0), 0.0, ph - 2.0)
    fs = num(b[:font_size], num(b[:h], 12.0)).abs
    fs = 1.0 if fs <= 0

    txt = sanitize_text(font, raw)
    next if txt.empty?

    begin
      canvas.font(font, size: fs)
      canvas.text(txt, at: [x, y])
      drew = true
    rescue => e
      warn "⚠️ page #{idx+1} text skipped: #{e.class}: #{e.message}"
    end
  end

  unless drew
    canvas.font(font, size: 12)
    canvas.text("Empty page #{idx+1}", at: [20, ph - 20])
  end
end

# validate and write
doc.validate(auto_correct: true)
doc.write(output, optimize: true, validate: true)

puts "Wrote: #{output} (#{File.size(output)} bytes)"
puts "Header: #{File.binread(output, 5).inspect}"
