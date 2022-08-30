module BulkUploadReportsHelper
  def custom_bulk_upload_reports_path
    admin_bulk_upload_reports_path
  end

  def filter_bulk_upload_report
    bulk_upload_docs = BulkUploadReport::DOCUMENT_TYPES
    if !current_client.enable_channel_partners?
      bulk_upload_docs.reject!{|doc| %w(channel_partners channel_partner_manager_change).include?(doc)}
    end
    if !current_client.enable_leads?
      bulk_upload_docs.reject!{|doc| %w(leads receipts).include?(doc)}
    end
    options = bulk_upload_docs.collect{ |doc| [t("mongoid.attributes.bulk_upload_report/file_types.#{doc}"), doc] }
    options
  end
end
