require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'

module MechanizeSpecHelper
  # shortcuts for mechanize
  def click(link)
    @page = agent.click(link)
  end

  def link(text)
    page.links.text(text).first
  end

  def click_link(text)
    click link(text)
  end

  def submit(form)
    @page = agent.submit(form)
  end

  def agent; @agent; end
  def page; @page; end

  # general spec helpers

  def assert(arg)
    arg.should.not.be.nil
  end

  # fast setup

  def register(nick, pass)
    click_link 'Join'
    form = page.form('/user/new')
    form.set_fields :nick => nick, :password_1 => pass, :password_2 => pass
    submit form
  end
end

shared 'mechanize' do
  Ramaze.skip_start

  # This sucks, very
  ARGV.concat ['--mode', 'spec']

  require 'start'

  Ramaze.start! :port => 7007,
    :adapter => :mongrel,
    :run_loose => true,
    :root => __DIR__/'..'

  require 'mechanize'
  port = Ramaze::Global.port

  extend MechanizeSpecHelper

  @agent = WWW::Mechanize.new
  @page = @agent.get("http://localhost:#{port}/")
end
