# app/services/pdf_parser.rb
require "hexapdf"

class PdfParser
  def self.call(document)
    document.pdf.open do |pdf_file|
      pdf = HexaPDF::Document.open(pdf_file)

      pages_json = []

      pdf.pages.each do |page|

        # --- Use HexaPDF's Processor ---
        

        # --- Images (resource dictionary can be nil; no #dig on PDF dicts) ---
        xobjects = page.resources && page.resources[:XObject]
        if xobjects
          xobjects.each do |name, xobj|
            next unless xobj[:Subtype] == :Image

            Tempfile.create(%w[img .bin]) do |tmp|   # not guaranteed PNG; store raw bytes
              tmp.binmode
              tmp.write(xobj.stream)                 # decoded stream bytes
              tmp.flush

              document.images.attach(
                io: File.open(tmp.path),
                filename: "#{name}.bin",
                content_type: "application/octet-stream"
              )
            end

            blob = document.images.last&.blob
            blocks << {
              type: "image",
              blob_id: blob&.signed_id,
              x: 100, y: 100,
              w: xobj[:Width], h: xobj[:Height]
            }
          end
        end

        pages_json << { blocks: blocks }
      end

      document.update!(layout_json: { pages: pages_json })
    end

    document
  rescue HexaPDF::Error => e
    Rails.logger.error("[PdfParser] Failed to parse PDF: #{e.message}")
    raise
  end
end
