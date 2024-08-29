class Parser  
  def get_case_name(file_content)
    doc = Nokogiri::HTML(file_content)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    json_object['caseDesc']
  end
  def get_case_number(file_content)
    doc = Nokogiri::HTML(file_content)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    json_object['caseNumber']
  end
  
  def get_court_id(case_number)
    court_id =
    if case_number.include?('OSCDB0024_SUP')
      326
    elsif case_number.include?('SMPDB0005_EAP')
      442
    elsif case_number.include?('SMPDB0001_SAP')
      443
    elsif case_number.include?('SMPDB0001_WAP')
      444
    elsif case_number.include?('SC')
      326
    elsif case_number.include?('ED')
      442
    elsif case_number.include?('SD')
      443
    elsif case_number.include?('WD')
      444 
    else
      0
    end
  end
  
  def add_data_soruce_md5(hash)
    hash['deleted'] = 0
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end

  def parse_case_info(file_content, case_name, case_number)
    hash = {}
    doc = Nokogiri::HTML(file_content)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    court_id_url = json_object['courtId']
    court_id = get_court_id(court_id_url)
    hash['court_id'] = court_id
    hash['case_id'] = case_number
    hash['case_name'] = case_name
    date_field =  json_object['filingDate']
    date = Date.strptime(date_field, '%m/%d/%Y')
    hash['case_filed_date'] = date.strftime('%Y-%m-%d')
    hash['case_type'] =  json_object['caseType']
    #hash['court_name'] =  json_object['location']
    hash['case_description'] = ''
    if json_object['caseDispositionDetail']['dispositionDescription'].present?
      hash['disposition_or_status'] = json_object['caseDispositionDetail']['dispositionDescription']
      hash['status_as_of_date'] = json_object['caseDispositionDetail']['dispositionDescription']
    else
      hash['disposition_or_status'] =''
      hash['status_as_of_date'] = ''
    end
    hash['judge_name'] = ''

    if !json_object['appellateCaseNo'].nil?
      hash['lower_case_id'] = json_object['appellateCaseNo']['caseValue']
      if json_object['appellateCaseNo']['courtId'].present?
        lower_case_id = json_object['appellateCaseNo']['courtId']
        hash['lower_court_id']  = get_court_id(lower_case_id)
      else
        hash['lower_court_id'] = 0
      end  
    else
      hash['lower_court_id'] = 0
      hash['lower_case_id'] = ''
    end
    data_source_url = "https://www.courts.mo.gov/cnet/cases/newHeaderData.do?caseNumber=#{case_number}&courtId=#{court_id_url}&isTicket=&locnCode="
    hash['data_source_url'] = data_source_url
    hash['deleted'] = 0
    hash['md5_hash'] = Digest::MD5.hexdigest(data_source_url)
    hash
  end
  
  def parse_activity_page(file_content,activity_url,case_number,court_id_url)
    court_id = get_court_id(court_id_url)
    doc = Nokogiri::HTML(file_content)
    @activities = []
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    act_details_list = json_object['docketTabModelList']
    act_details_list.each do |act|
      date_field = act['filingDate']
      date = Date.strptime(date_field, '%m/%d/%Y')
      if !act['associatedDocketInfoDetails'].nil?
         act_desc = act['docketText'] + " " + act['associatedDocketInfoDetails']['associatedDate'] + " " + act['associatedDocketInfoDetails']['associatedDescription']+ act['associatedDocketInfoDetails']['associatedText']
      else
        act_desc = act['docketText']
      end  
      @activities.push({
        court_id: court_id,
        case_id: case_number,
        activity_date: date.strftime('%Y-%m-%d'),
        activity_type: act['docketDesc'],
        activity_desc: act_desc,
        file: nil,
        data_source_url: activity_url
        })
    end
    @activities = @activities.map {|hash| add_data_soruce_md5(hash)}
    @activities 
    
  end
  def parse_party_info(file_content, party_url,c_number,court_id_url)
    doc = Nokogiri::HTML(file_content)
    json_string = doc.at('p').text
    json_object = JSON.parse(json_string)
    party_details_list = json_object['partyDetailsList']
    court_id = get_court_id(court_id_url)
    parties = []
    party_details_list.each do |party|
    is_lawyer = 0
    parties.push({
        court_id: court_id,
        case_id: c_number,
        party_name: party['formattedPartyName'],
        party_type: party['desc'],
        is_lawyer: is_lawyer,
        party_law_firm: '',
        party_address: party['formattedPartyAddress'].gsub("\n", ''),
        party_city: party['addrCity'],
        party_state: party['addrStatCode'],
        party_zip: party['addrZip'],
        party_description: party['formattedTelePhone'],
        data_source_url: party_url
      })
    attorney_list = party['attorneyList']
      if !attorney_list.empty?
        is_lawyer = 1
        attorney = attorney_list[0]
        parties.push({
          court_id: court_id,
          case_id: c_number,
          party_name: attorney['formattedPartyName'],
          party_type: attorney['desc'],
          is_lawyer:is_lawyer,
          party_law_firm: '',
          party_address: attorney['formattedPartyAddress'].gsub("\n", ''),
          party_city: attorney['addrCity'],
          party_state: attorney['addrStatCode'],
          party_zip: attorney['addrZip'],
          party_description: attorney['formattedTelePhone'],
          data_source_url: party_url
          })
        co_attorney_list = attorney['coAttorneyList']
        unless co_attorney_list.nil?
          co_attorney_list.each do |co_attorney|
            parties.push({
              court_id: court_id,
              case_id: c_number,
              party_name: co_attorney['formattedPartyName'],
              party_type: co_attorney['desc'],
              is_lawyer:is_lawyer,
              party_law_firm: '',
              party_address: co_attorney['formattedPartyAddress'].gsub("\n", ''),
              party_city: co_attorney['addrCity'],
              party_state: co_attorney['addrStatCode'],
              party_zip: co_attorney['addrZip'],
              party_description: co_attorney['formattedTelePhone'],
              data_source_url: party_url

              })
          end
        end  
      end
    end
    parties = parties.map {|hash| add_data_soruce_md5(hash)}
    parties
  end  
  
  def parse_opinion_page(file_content, file_name)
    year = file_name.match(/(\d{4})\.html$/)[1]
    doc = Nokogiri::HTML(file_content)
    url = "https://www.courts.mo.gov/page.jsp?id=12086&dist=Opinions&date=all&year=#{year}#all"
    opinion_files = []
    doc.css(".panel-heading.sr-only").each do |date_div|
      date = date_div.text.strip
      date = Date.strptime(date, '%m/%d/%Y')
      date = date.strftime('%Y-%m-%d')
      cases_div = date_div.parent.css(".list-group").css('.list-group-item')
      cases_div.each do |case_div| 
        links = case_div.css('a').select {|a| a['href'] =~ /file\.jsp/ && a.text !~ /Orders/ && a.text !~ /Overview/}
        pdf_link = links.map {|a| a['href']}.flatten
        pdf_link = pdf_link.join(", ")
        source_link = "https://www.courts.mo.gov#{pdf_link}"
        pdf_link_md5_hash = Digest::MD5.hexdigest(source_link)
        if case_div.css('.list-group-item-text b:first-child').text && !case_div.css('.list-group-item-text b:first-child').text.include?('Order')
          case_numbers = []
          case_id = case_div.css('.list-group-item-text b:first-child').text
          case_id = case_id.split(':').first
          case_numbers2 = case_id.scan(/\b([A-Z]{2}\d+(?:_[A-Z0-9]+)*)(?=[\s,]|$)/)
          case_id.scan(/\b([A-Z]{2}\d+(?:_[A-Z0-9]+)*)(?=[\s,_]|$|\band\b)/i) do |matches| 
            case_numbers2 = matches[0].split(/_|\band\b/)
            case_numbers += case_numbers2
          end
          case_numbers.map! { |case_number| case_number.gsub(/consolidated|with|and/, "")}
          if case_numbers.length > 1
            case_numbers.each do |cases|
            court_id = get_court_id(cases.to_s)
            if !(cases == "")
              opinion_files << {
                court_id: court_id,
                case_id: cases,
                case_date: date,
                source_type: 'activity',
                source_link: source_link,
                aws_html_link: 'nil',
                data_source_url: url,
                deleted: 0,
                md5_hash: pdf_link_md5_hash
              }
            end
            end
          end
        end
        if case_id && !(case_numbers.length > 1)
          court_id = get_court_id(case_numbers.to_s)
          opinion_files << {
            court_id: court_id,
            case_id: case_id,
            case_date: date,
            source_type: 'activity',
            source_link: source_link,
            aws_html_link: 'nil',
            data_source_url: url,
            deleted: 0,
            md5_hash: pdf_link_md5_hash
          }
        end
      end
    end
    opinion_files
  end
  end