class Scraper < Hamster::Scraper
  def initialize
    super
    @s3 = AwsS3.new(bucket_key = :us_court)
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {| response | ![200, 304].include?(response.status) || response.body.size.zero? }
  end
  
  def download_page(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url, proxy_filter: @proxy_filter,method: :get, headers: HEADERS_PAGE)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10 
    [response, response&.status]    
  end
  
  def store_pdf_to_aws(pdf_link, court_id, case_id)
    pdf_link_md5_hash = Digest::MD5.hexdigest(pdf_link) + '.pdf'
    pdf_storage_path = @_storehouse_ + "store/#{pdf_link_md5_hash}"
    key = "us_courts_expansion_#{court_id}_#{case_id}_#{pdf_link_md5_hash}"
    aws_link = nil
    if File.file?(pdf_storage_path)
      aws_link = @s3.put_file(File.open(pdf_storage_path), key, metadata = { url: pdf_link})
    end
    aws_link
  end
  
  private
  def reporting_request(response)
    if response.present?
      puts '=================================='.yellow
      print 'Response status: '.indent(1, "\t").green
      status = "#{response.status}"
      puts response.status == 200 ? status.greenish : status.red
      puts '=================================='.yellow
    end
  end
  end