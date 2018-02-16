class AdminController < ApplicationController
  layout :set_layout
  protect_from_forgery prepend: true

  def set_layout
    if action_name.starts_with? 'verify_'
      'audits_common/admin_verification_layout'
    else
      'audits_common/admin_layout'
    end
  end

  def index
    @section_title = 'Admin'
  end

  def add_object
    @section_title = 'Add A Generic Object'
    self.set_available_systems
  end

  def verify_batch_documents
    @section_title = 'Batch Document Updater'

    set_form_data params[:batch_documents]

    systems = get_form_data :systems
    sections = get_form_data :sections
    update_subsections = get_form_data :sections_checkbox
    document_ids = get_form_data :documents
    preserve_documents = get_form_data :documents_checkbox

    # Add in the appropriate subsections if that checkbox was selected.
    sections = get_section_children(sections) if update_subsections || sections.include?("ALL")

    @verify_hash = {}
    sections.each do |sec|
      if AuditsCommon::Utils::Admin.is_section_editable(sec)
        @verify_hash[sec.to_s] = {}
        @verify_hash[sec.to_s][:current] = AuditsCommon::Utils::Admin.get_current_answer_state(systems, sec, 'All', { section_id: sec })
        @verify_hash[sec.to_s][:future] = AuditsCommon::Utils::Admin.batch_update_documents(false, systems, sec, document_ids, preserve_documents)

        # Add in the fields we didn't care about for this update
        @verify_hash[sec.to_s][:future].keys.each do |key|
          @verify_hash[sec.to_s][:future][key][:systems] = @verify_hash[sec.to_s][:current][key][:systems]
          @verify_hash[sec.to_s][:future][key][:body] = @verify_hash[sec.to_s][:current][key][:body]
          @verify_hash[sec.to_s][:future][key][:owner] = @verify_hash[sec.to_s][:current][key][:owner]
          @verify_hash[sec.to_s][:future][key][:status] = @verify_hash[sec.to_s][:current][key][:status]
        end
      end
    end

    @exclude_keys = ['n/a', 'null']
    @match_result_hash = true
  end

  def run_batch_documents
    @section_title = 'Batch Document Updater'
    systems = get_form_data :systems
    sections = get_form_data :sections
    update_subsections = get_form_data :sections_checkbox
    document_ids = get_form_data :documents
    preserve_documents = get_form_data :documents_checkbox

    # Add in the appropriate subsections if that checkbox was selected.
    sections = get_section_children(sections) if update_subsections || sections.include?("ALL")

    sections.each do |sec|
      ActiveRecord::Base.transaction do
        AuditsCommon::Utils::Admin.batch_update_documents(true, systems, sec, document_ids, preserve_documents) if sec.present? && document_ids.present? && document_ids[0].present?
      end
    end

    flash[:success] = "Batch documents were updated!"
    redirect_to audits_common.admin_home_path(audit_id: params[:audit_id])
  end
end
