require 'rubygems'
require 'selenium-webdriver'
require 'yaml'

# 
# Read the config file
#
config = YAML.load_file("config.yaml")
config["config"].each { |key, value| instance_variable_set("@#{key}", value) }

browser = Selenium::WebDriver.for :firefox

browser.get @vcl_url

#
# The first index pages forces a choice of login authentciation types
# even if there is only one type, ie. local. Just hit submit.
# 
auth_form =  browser.find_element(:name, "loginform")
auth_form.submit

#
# The next page should be the actual login page so find the loginform
# and send userid and password.
#
password = browser.find_element(:name, "password")
password.send_keys @password
userid = browser.find_element(:name, "userid")
userid.send_keys @userid

#
# Submit the login form
# 
login_form = browser.find_element(:name, 'loginform')
login_form.submit

sleep 1

#  
# Click on 'New Reservations'
#
browser.find_element(:link,'New Reservation').click

#
# Setting wait time, not 100% sure what this does...
# 
browser.manage.timeouts.implicit_wait = 10

# Sleep for a few seconds
sleep 5

# 
# The next page will just have the reservation request form
# and we should be able to just pick the default "now" time
# and default "environment" or image
# 
reservation_form = browser.find_element(:id, 'newsubmit')

#
# If the reservation form goes through, then go onto the viewRequests
#
if reservation_form.submit
	browser.get "https://caas-test.cybera.ca/index.php?mode=viewRequests"
else
	puts "ERROR: Reservation form submit failed"
	# exit
	browser.quit
end

#
# Wait for the connect button
#
$total_sleep = 0
while $total_sleep < @max_wait_for_connection do
	#if browser.find_element(:id, 'dijit_form_Button_0').click
	#if browser.find_element(:xpath, '//button[contains(text(), \'Connect!\')]').click
	puts "LOG: Total sleep is " + $total_sleep.to_s
	$total_sleep = $total_sleep + 10
	#
	#  Use a begin to ignore the exception thrown if browser can't find an
	#  element with "Connect"...I guess with '*' we are looking for any element
	#  that contains text, which is probably wrong. I tried "button" though.
	#
	begin
		if browser.find_element(:xpath, "//*[contains(text(),'Connect')]").click
			puts "LOG: found element containing 'Connect'! Yay!"
			break
		end
	rescue
		puts "LOG: Couldn't find Connect button, sleeping 10 and trying again..."
		sleep 10
		next
	end

end

# Don't work....xpath 2.0 has support for regexes, but I can't even find out what version of xpath  is
# being used here...
#remote_computer = browser.find_element(:xpath, "//*[contains(text(), '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$')]").text
#remote_password = browser.find_element(:xpath, "//*[contains(text(), 'Password')]/following-sibling::node()").text
#remote_computer = browser.find_element(:xpath, "//*[contains(text(), 'Remote Computer')]/following-sibling::node()").text
#remote_computer = browser.find_element(:xpath, "//*[contains(text(), '^.*199.*$')]").text
#/html/body/table/tbody/tr/td[4]/table[2]/tbody/tr/td[2]/div/ul/li
#remote_computer = browser.find_element(:xpath, "//*[contains(text(), '^.*199.*$')]").text
#driver.find_element(:xpath,"//table[contains(@id,'searchTable')]/tbody/tr[contains(@code,"PowerSelect")]/td").click
#/html/body/table/tbody/tr/td[4]/table[2]/tbody/tr/td[2]/div/ul/li[2]

# This works, but might be brittle...
remote_computer = browser.find_element(:xpath, "/html/body/table/tbody/tr/td[4]/table[2]/tbody/tr/td[2]/div/ul/li").text
remote_password = browser.find_element(:xpath, "/html/body/table/tbody/tr/td[4]/table[2]/tbody/tr/td[2]/div/ul/li[3]").text

remote_connection_info = /\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\:[0-9]{5}\b/.match(remote_computer)
remote_password_info = /\b\w{6}\b/.match(remote_password)

puts "LOG: remove connection info " + remote_connection_info.to_s
puts "LOG: remote password is " + remote_password_info.to_s

puts "LOG: Exiting..."

# Quit the browswer
browser.quit