module BulkUploadReportsHelper
  def custom_bulk_upload_reports_path
    admin_bulk_upload_reports_path
  end

  def filter_bulk_upload_report client
    bulk_upload_docs = BulkUploadReport::DOCUMENT_TYPES
    resultant_docs = []

    resultant_docs = if !client.enable_channel_partners? && client.enable_leads?
      reject_cp_docs(bulk_upload_docs)
    elsif client.enable_channel_partners? && !client.enable_leads?
      reject_lead_docs(bulk_upload_docs)
    elsif !client.enable_channel_partners? && !client.enable_leads?
      reject_cp_docs(bulk_upload_docs) & reject_lead_docs(bulk_upload_docs)
    else
      bulk_upload_docs
    end
    options = resultant_docs.collect{ |doc| [t("mongoid.attributes.bulk_upload_report/file_types.#{doc}"), doc] }
    options
  end

  def reject_cp_docs bulk_upload_docs
    resultant_cp_docs = bulk_upload_docs.reject{|doc| %w(channel_partners channel_partner_manager_change channel_partner_user).include?(doc)}
  end

  def reject_lead_docs bulk_upload_docs
    resultant_lead_docs = bulk_upload_docs.reject{|doc| %w(leads receipts).include?(doc)}
  end
end
