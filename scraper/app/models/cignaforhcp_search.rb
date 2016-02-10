class CignaforhcpSearch < ActiveRecord::Base

  #TODO Exception handling is not done in any step.
  #TODO Move each step of the scraping process to its own method
  #NOTE: css search is used everywhere, instead of xpath.
  #TODO: Scraper logic can be moved out to a separate module.

  def execute
    require "mechanize"
    agent = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
    agent.ssl_version = 'TLSv1'
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

    #Login
    login_form = agent.get("https://cignaforhcp.cigna.com/web/public/guest/").form('userForm')
    login_form.username = ''
    login_form.password = ''
    logged_page = login_form.submit

    #Hard coded headers.
    headers = {'X-Requested-With' => 'XMLHttpRequest', 'Content-Type' => 'application/json', 'Accept' => 'application/json, text/javascript, */*; q=0.01', 'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.65 Safari/537.36', 'Host' => 'cignaforhcp.cigna.com', 'Origin' => "https://cignaforhcp.cigna.com", 'Referer' => 'https://cignaforhcp.cigna.com/web/secure/chcp/windowmanager' }

    #To get JSON data containing search page url, we need to post to an url, burried inside a <script> tag
    window_url = logged_page.search('script')[5].children.first.text.scan(/windowManagerRequestUrl.*/).first.split(' ').last.gsub("'", '').gsub(';', '')

    search_window_json = agent.post(window_url, {command: "loadWorkspace", componentTemplate:{containerType: "TAB", title: "skedia105"}, workspace: nil}.to_json, headers)
  
    search_tab_hash = JSON.parse(search_window_json.body)["workspace"]["windows"].first["children"].first["children"].select {|tab| tab["titleCode"] == "page.title.patientsearch" }.first

    search_page_url = "https://cignaforhcp.cigna.com#{search_tab_hash["url"]}"
    search_page = agent.post(search_page_url, '', headers)
    search_form = search_page.form

    #Set values to search form and submit. Any three combinations are enough. So disabled DOB
    search_form.field_with(id: /patientId/).value = self.patient_id
    #search_form.field_with(id: /patientDOB/).value = '11/14/1956'
    search_form.field_with(id: /subLastName/).value = self.last_name
    search_form.field_with(id: /subFirstName/).value = self.first_name
    search_results_page = search_form.submit

    #We get table with list of patients. First column link to patient details
    results_table = search_results_page.search('table.patient-search-result-table')

    open_patient_payload = results_table.first.search('tbody').search('tr').attr('class').value.gsub('patient-search-result', '').gsub('filtered-even', '').gsub('filtered-last', '')

    open_patient_payload = JSON.parse(open_patient_payload)
 
    patient_url = results_table.first.search('tbody').search('tr').first.search('a').attr('href').text
    patient_url = "https://cignaforhcp.cigna.com#{patient_url}"

    headers['Content-Type'] = 'application/x-www-form-urlencoded'
    headers['Accept'] = 'text/html, */*; q=0.01'
    patient_page = agent.post(patient_url, {membersummaryjson: open_patient_payload["membersummary"].to_json}, headers)

    return patient_page.search('.collapseTable-container').search('table.datatable')
  end
end
