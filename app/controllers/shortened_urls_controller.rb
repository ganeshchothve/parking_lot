class ShortenedUrlsController < ApplicationController

  def redirect_to_url
    @url = ShortenedUrl.where(code: params[:code]).first
    respond_to do |format|
      if @url.present?
        format.html { redirect_to @url.original_url, status: :moved_permanently }
      else
        format.html { redirect_to root_path, notice: 'Incorrect URL' }
      end
    end
  end
end