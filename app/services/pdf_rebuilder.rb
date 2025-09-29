require 'hexapdf'

class PdfRebuilder
  def self.call(document)
    pdf = HexaPDF::Document.new

    document.layout_json["pages"].each do |page_data|
      page = pdf.pages.add
      canvas = page.canvas

      page_data["blocks"].each do |b|
        case b["type"]
        when "text"
          canvas.font("Helvetica", size: 12)
          canvas.text(b["text"], at: [b["x"], b["y"]])
        when "image"
          blob = ActiveStorage::Blob.find_signed(b["blob_id"])
          img_path = ActiveStorage::Blob.service.send(:path_for, blob.key)
          image = pdf.images.add(img_path)
          canvas.image(image, at: [b["x"], b["y"]], width: b["w"], height: b["h"])
        end
      end
    end

    io = StringIO.new
    pdf.write(io)
    document.pdf.attach(io: StringIO.new(io.string), filename: "#{document.title}_edited.pdf")
  end
end
