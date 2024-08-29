require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @partyfilenames = []
  end

  def download_store
    cases = ['SC96866', 'ED106263', 'WD83687', 'SD37739']
    cases.each do |case_number|
      case_prefix = case_number[0, 2]
      start_number = case_number[2..-1].to_i
      if case_prefix.include?('SC')
        court_id_url = 'OSCDB0024_SUP'
        end_number = 99984
      elsif case_prefix.include?('ED')
        court_id_url = 'SMPDB0005_EAP'
        end_number = 111419
      elsif case_prefix.include?('WD')
        court_id_url = 'SMPDB0001_WAP'
        end_number = 83698
      elsif case_prefix.include?('SD')
        court_id_url = 'SMPDB0001_SAP'
        end_number = 37899
      end
      while start_number <= end_number do
        c_number = "#{case_prefix}#{start_number}"
        url = "https://www.courts.mo.gov/cnet/cases/newHeaderData.do?caseNumber=#{c_number}&courtId=#{court_id_url}&isTicket=&locnCode="
        party_url = "https://www.courts.mo.gov/cnet/cases/party.do?caseNumber=#{c_number}&courtId=#{court_id_url}&isTicket="
        activity_url = "https://www.courts.mo.gov/cnet/cases/docketEntriesSearch.do?displayOption=A&sortOption=D&hasChange=false&caseNumber=#{c_number}&courtId=#{court_id_url}&isTicket="
        page_response, status = @scraper.download_page(url)
        party_url_response, status = @scraper.download_page(party_url)
        activity_url_response, status = @scraper.download_page(activity_url)
        case_name = @parser.get_case_name(page_response.body)
        all_records = @parser.parse_case_info(page_response.body, case_name, c_number)
        @keeper.store_ca_info(all_records)
        party_info = @parser.parse_party_info(party_url_response.body,party_url,c_number,court_id_url)  
        @keeper.store_party_info(party_info)
        activity_info = @parser.parse_activity_page(activity_url_response.body,activity_url,c_number,court_id_url)
        @keeper.store_case_activity(activity_info)
        start_number += 1
      end
      return if status != 200
    end

    (2018..Date.today.year).each do |year|
      url = "https://www.courts.mo.gov/page.jsp?id=12086&dist=Opinions&date=all&year=#{year}#all"
      page_response, status = @scraper.download_page(url)
      file_name = "opinion_#{year}.html"
      @partyfilenames << file_name
      save_file(page_response, file_name)
    end
  end

  def store
    begin
      process_each_file
      @keeper.finish
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Mashal Ahmad', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end
 
  def process_each_file
   @partyfilenames.each do | file_name |
   if file_name.include?("opinion_")
     file_content = peon.give(file: file_name)
     pdf_info = @parser.parse_opinion_page(file_content, file_name)
     new_pdf = {}
     pdf_info.each do |value|
       court_id = value[:court_id]
       case_id = value[:case_id]
       case_date = value[:case_date]
       source_type = value[:source_type]
       pdf_link = value[:source_link]
       aws_html_link = value[:aws_html_link]
       data_source_url = value[:data_source_url]
       deleted = value[:deleted]
       md5_hash = value[:md5_hash]
       if ('SC95452'..'SC99984').include?(case_id) || ('ED103841'..'ED111419').include?(case_id) || ('WD83687'..'WD83698').include?(case_id) || ('SD37739'..'SD37899').include?(case_id)
         pdf_response, status = @scraper.download_page(pdf_link)
         pdf_link_md5_hash = Digest::MD5.hexdigest(pdf_link) + '.pdf'
         save_pdf(pdf_response&.body, pdf_link_md5_hash) if status == 200
         aws_link = @scraper.store_pdf_to_aws(pdf_link, court_id, case_id)
         new_pdf = new_pdf.merge(court_id: court_id, case_id: case_id, case_date: case_date, source_type: source_type, source_link: pdf_link, aws_link: aws_link, aws_html_link: aws_html_link, data_source_url: data_source_url, deleted: deleted, md5_hash: md5_hash)
         @keeper.store_opinion_files(new_pdf)
         activity_info_relation_hash = {}
         result = @keeper.get_ca_activity_md5(case_id, case_date)
         if result.nil?
            next
         end
         result.each do |value|
            activity_info_relation_hash['court_id'] = court_id
            activity_info_relation_hash['case_activities_md5'] = value
            activity_info_relation_hash['case_pdf_on_aws_md5'] = pdf_link_md5_hash
            activity_info_relation_hash['md5_hash'] = Digest::MD5.hexdigest(value + pdf_link_md5_hash)
            @keeper.store_relation_hashes(activity_info_relation_hash)
         end
       else
          next
       end
     end
   end
   end
  end  

  private
  def save_pdf(pdf , file_name)
   pdf_storage_path = @_storehouse_ + "store/#{file_name}"
   File.open(pdf_storage_path, "wb") do |f|
     f.write(pdf)
   end
  end

  def save_file(html, file_name) 
    peon.put content: html.body, file: "#{file_name}"
  end
end    