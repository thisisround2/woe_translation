# app/controllers/documents_controller.rb
class DocumentsController < ApplicationController
  def new
    @doc = Document.new
  end

  def create
    @doc = Document.create!(doc_params)
    @doc.pdf.attach(doc_params[:pdf])
    # Parse text + images into layout JSON
    PdfParser.call(@doc)
    redirect_to edit_document_path(@doc)
  end

  def edit
    @doc = Document.find(params[:id])
  end

  def update_layout
    @doc = Document.find(params[:id])
    @doc.update!(layout_json: params[:layout_json])
    head :ok
  end

  def export
    @doc = Document.find(params[:id])
    PdfRebuilder.call(@doc)
    redirect_to rails_blob_path(@doc.pdf, disposition: "attachment")
  end

  private

  def doc_params
    params.require(:document).permit(:title, :pdf)
  end
end
