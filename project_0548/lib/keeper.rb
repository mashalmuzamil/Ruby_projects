require_relative '../models/mo_saac_ca_info'
require_relative '../models/mo_saac_ca_info_runs'
require_relative '../models/mo_saac_ca_ad_info'
require_relative '../models/mo_saac_case_party'
require_relative '../models/mo_saac_case_activity'
require_relative '../models/mo_saac_case_pdf_aws'
require_relative '../models/mo_saac_case_relations_activity_pdf'

class Keeper
  def initialize
    @run_object = RunId.new(MoSaacCaInfoRuns)
    @run_id = @run_object.run_id
  end

  def ad_ids(hash)
    if !hash.nil?
      hash['run_id'] = @run_id
      hash['touched_run_id'] = @run_id
    end  
    hash
  end  

  def store_ca_info(hash)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    MoSaacCaInfo.insert(hash)
  end

  def store_ca_ad_info(hash)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    MoSaacCaAdInfo.insert(hash)
  end
    
  def store_party_info(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    MoSaacCaseParty.insert_all(list_of_hashes)
  end

  def store_case_activity(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    MoSaacCaseActivity.insert_all(list_of_hashes)
  end

  def get_ca_activity_md5(case_id,case_date)
    md5_hashes = MoSaacCaseActivity.where(activity_date: case_date, case_id: case_id).where('activity_type LIKE ?', '%opinion%').pluck(:md5_hash)
  end

  def store_opinion_files(hash)
    hash = ad_ids(hash)
    MoSaacCasePdfAws.insert(hash)
  end
   
  def store_relation_hashes(hash)
    hash = ad_ids(hash)
    MoSaacCaseRelationsActivityPdf.insert(hash)
  end
  
  def finish
    @run_object.finish
  end
end
