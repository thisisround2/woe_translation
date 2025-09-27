require "google/cloud/translate/v2"

class TranslationsController < ApplicationController
  MIME_MAP = {
    ".pdf"  => "application/pdf",
    ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation"
  }.freeze

  def new

  end

  def create
    uploaded = params.require(:file)
    ext      = File.extname(uploaded.original_filename).downcase
    mime     = MIME_MAP[ext] || uploaded.content_type || "application/octet-stream"

    target = (params[:target].presence || "en")
    source = params[:source].presence # let Google auto-detect if nil

    # read bytes
    content = uploaded.read

    #client = Google::Cloud::Translate.new
    
    client = Google::Cloud::Translate.translation_service

    parent = "projects/748012539858/locations/global"

    resp = client.translate_document(
      parent: parent,
      target_language_code: target,
      source_language_code: source, # nil is OK
      document_input_config: {
        mime_type: mime,   # required for byte uploads
        content:   content # raw bytes
      }
      # document_output_config: { mime_type: mime } # optional; defaults to same as input
    )

    bytes = resp.document_translation.byte_stream_outputs.first
    send_data bytes,
      filename: translated_name(uploaded.original_filename, target),
      type: resp.document_translation.mime_type || mime,
      disposition: "inline"
  rescue => e
    redirect_to new_translation_path, alert: "Translation failed: #{e.message}"
    puts "#{e.message}"
  end

  private

  def translated_name(orig, target)
    base = File.basename(orig, ".*")
    ext  = File.extname(orig)
    "#{base}.#{target}#{ext}"
  end
end
