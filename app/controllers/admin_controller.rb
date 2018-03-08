class AdminController < ApplicationController
  before_action :admin_login_required

  def edit_2007_2008_schedule
    fname = "#{RAILS_ROOT}/app/views/index/2007_2008_schedule.rhtml"
    case request.method
    when :get
      @text = File.read(fname)
      render
      return
    when :post
      f = File.open(fname, "w+")
      f << params[:text]
      f.close
      flash.now[:success] = "saved the new text"
      @text = File.read(fname)
      render
      return
    end
  end

  def edit_email
    fname = "#{RAILS_ROOT}/app/views/notifications/#{params[:em]}.rhtml"
    @em = params[:em]
    case request.method
    when :get
      @text = File.read(fname)
      render
      return
    when :post
      f = File.open(fname, "w+")
      f << params[:text]
      f.close
      flash.now[:success] = "saved the new text"
      @text = File.read(fname)
      render
      return
    end
  end

  def edit_welcome
    fname = "#{RAILS_ROOT}/app/views/index/_index_header.rhtml"
    case request.method
    when :get
      @text = File.read(fname)
      render
      return
    when :post
      f = File.open(fname, "w+")
      f << params[:text]
      f.close
      flash.now[:success] = "saved the new text"
      @text = File.read(fname)
      render
      return
    end
  end

  def edit_group_tickets
    fname = "#{RAILS_ROOT}/app/views/index/group_tickets.rhtml"
    case request.method
    when :get
      @text = File.read(fname)
      render
      return
    when :post
      f = File.open(fname, "w+")
      f << params[:text]
      f.close
      flash.now[:success] = "saved the new text"
      @text = File.read(fname)
      render
      return
    end
  end

  def edit_about
    case request.method
    when :get
      @text = File.read("#{RAILS_ROOT}/app/views/index/about.rhtml")
      render
      return
    when :post
      f = File.open("#{RAILS_ROOT}/app/views/index/about.rhtml", "w+")
      f << params[:text]
      f.close
      flash.now[:success] = "saved the new text"
      @text = File.read("#{RAILS_ROOT}/app/views/index/about.rhtml")
      render
      return
    end
  end

  def edit_help
    case request.method
    when :get
      @text = File.read("#{RAILS_ROOT}/app/views/index/help.rhtml")
      render
      return
    when :post
      f = File.open("#{RAILS_ROOT}/app/views/index/help.rhtml", "w+")
      f << params[:text]
      f.close
      flash.now[:success] = "saved the new text"
      @text = File.read("#{RAILS_ROOT}/app/views/index/help.rhtml")
      render
      return
    end
  end

  def edit_weekly_shuttle
    case request.method
    when :get
      @text = File.read("#{RAILS_ROOT}/app/views/index/weekly_shuttle.rhtml")
      render
      return
    when :post
      f = File.open("#{RAILS_ROOT}/app/views/index/weekly_shuttle.rhtml", "w+")
      f << params[:text]
      f.close
      flash.now[:success] = "saved the new text"
      @text = File.read("#{RAILS_ROOT}/app/views/index/weekly_shuttle.rhtml")
      render
      return
    end
  end
end
