class ShortenedUrlsController < ApplicationController
  before_action :set_shortened_url

  def redirect_to_url
    respond_to do |format|
      if @url.present? && !@url.expired?
        format.html { redirect_to @url.original_url, status: :moved_permanently }
      else
        format.html { redirect_to root_path, alert: t("controller.shortened_urls.alert.not_found") }
      end
    end
  end

  private

  def set_shortened_url
    client_id, code = params[:code].split("-")
    if client_id.present? && code.present?
      @url = ShortenedUrl.where(booking_portal_client_id: client_id, code: code).first
    else
      redirect_to root_path, alert: t("controller.shortened_urls.alert.not_found")
    end
  end
end