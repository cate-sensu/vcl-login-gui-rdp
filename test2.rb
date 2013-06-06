
require 'rubygems'
require 'mechanize'

agent = Mechanize.new
agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE


agent.get('https://caas-test.cybera.ca') do |page|
	auth_selection_form = agent.page.form_with(:name => "loginform")
	# get the button you want from the form
	auth_selection_button = auth_selection_form.button_with(:value => "userid")
	# submit the form using that button
	login_page = agent.submit(auth_selection_form, auth_selection_button)
	pp login_page


	login_form = login_page.form_with(:name => "loginform")
	login_form.userid = 'curtis'
	login_form.password = 'curtis'
	login_button = login_form.button_with(:value => "Login")
	
	dashboard_page = agent.submit(login_form, login_button)

	pp dashboard_page

	new_reservation_page = agent.click(dashboard_page.link_with(:text => /New Reservation/))

	pp new_reservation_page
end
