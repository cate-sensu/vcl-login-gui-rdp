#!/usr/bin/env ruby
#
# Check HTTP
# ===
#
# Takes either a URL or a combination of host/path/port/ssl, and checks for
# a 200 response (that matches a pattern, if given). Can use client certs.
#
# Copyright 2011 Sonian, Inc <chefs@sonian.net>
# Updated by Lewis Preson 2012 to accept basic auth credentials
# Updated by SweetSpot 2012 to require specified redirect
# Updated by Chris Armstrong 2013 to accept multiple headers
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'selenium-webdriver'
#require 'yaml'

class CheckVCL < Sensu::Plugin::Check::CLI

  option :host, :short => '-h HOST'
  option :user, :short => '-U', :long => '--username USER'
  option :password, :short => '-a', :long => '--password PASS'
  # 20 minutes
  max_wait_for_connection = 1200

  def run
    if config[:host]
      vcl_host = config[:host]
      vcl_user = config[:user]
      vcl_password = config[:password]
    else

    if [vcl_host, vcl_user, vcl_pass].any? {|v| v.nil? }
      unknown "Must specify host, user, password"
    end
      
    #
    # Start the browswer
    # 
    browser = Selenium::WebDriver.for :firefox
    begin 
      browser.get "https://" + $vcl_host 
      ok "browser accessed url"
    rescue
      critical "can't access host via https"
    end

    #
    # The first index pages forces a choice of login authentciation types
    # even if there is only one type, ie. local. Just hit submit.
    # 
    auth_form =  browser.find_element(:name, "loginform")
    
    begin 
      auth_form.submit
      ok "auth form submitted"
    rescue
      critical "can't submit auth form"
    end

    #
    # The next page should be the actual login page so find the loginform
    # and send userid and password.
    #
    begin
      password = browser.find_element(:name, "password")
      password.send_keys $vcl_password
      userid = browser.find_element(:name, "userid")
      userid.send_keys $vcl_user
      ok "sent keys for userid and password"
    rescue
      critical "couldn't send keys for userid and passsword"
    end

    #
    # Submit the login form
    # 
    login_form = browser.find_element(:name, 'loginform')
    begin 
      login_form.submit
      ok "login form submitted"
    rescue
      critical "can't submit loging form"
    end

    #  
    # Click on 'New Reservations'
    #
    browser.find_element(:link,'New Reservation').click

    #
    # Setting wait time, not 100% sure what this does...
    # 
    browser.manage.timeouts.implicit_wait = 10

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
      ok "reservation form submitted"
      browser.get "https://caas-test.cybera.ca/index.php?mode=viewRequests"
    else
      critical "Couldn't submit reservation form"
      browser.quit
    end

    #
    # Wait for the connect button
    #
    $total_sleep = 0
    while $total_sleep < $max_wait_for_connection do
      #if browser.find_element(:id, 'dijit_form_Button_0').click
      #if browser.find_element(:xpath, '//button[contains(text(), \'Connect!\')]').click
      ok "total sleep is " + $total_sleep.to_s
      $total_sleep = $total_sleep + 10
      #
      #  Use a begin to ignore the exception thrown if browser can't find an
      #  element with "Connect"...I guess with '*' we are looking for any element
      #  that contains text, which is probably wrong. I tried "button" though.
      #
      begin
        if browser.find_element(:xpath, "//*[contains(text(),'Connect')]").click
          ok "found element containing 'Connect'! Yay!"
          break
        end
      rescue
        ok "Couldn't find Connect button, sleeping 10 and trying again..."
        sleep 10
        next
      end

    end

    # Brittle...
    begin
      remote_computer = browser.find_element(:xpath, "/html/body/table/tbody/tr/td[4]/table[2]/tbody/tr/td[2]/div/ul/li").text
      remote_connection_info = /\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\:[0-9]{5}\b/.match(remote_computer)
      ok "found remote computer connection information"
    rescue
      critical "couldn't find remote computer connection information"
    end

    begin
      remote_password = browser.find_element(:xpath, "/html/body/table/tbody/tr/td[4]/table[2]/tbody/tr/td[2]/div/ul/li[3]").text
      remote_password_info = /\b\w{6}\b/.match(remote_password)
      ok "found remote password information"
    rescue
      critical "couldn't find remote password information"
    end


    ok "remove connection info " + remote_connection_info.to_s
    ok "remote password is " + remote_password_info.to_s

    ok "LOG: Exiting..."

    # Quit the browswer
    browser.quit
    exit 0

end
