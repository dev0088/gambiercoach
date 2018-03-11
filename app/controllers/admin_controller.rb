class AdminController < ApplicationController
  before_action :admin_login_required

  def edit_email
    fname = "#{Rails.root}/app/views/notifications/#{params[:em]}.html.erb"
    @em = params[:em]
    case request.method
    when 'GET'
      @text = File.read(fname)
      render
      return
    when 'POST'
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
    fname = "#{Rails.root}/app/views/index/_index_header.html.erb"
    case request.method
    when 'GET'
      @text = File.read(fname)
      render
      return
    when 'POST'
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
    fname = "#{Rails.root}/app/views/index/group_tickets.html.erb"
    case request.method
    when 'GET'
      @text = File.read(fname)
      render
      return
    when 'POST'
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
    when 'GET'
      @text = File.read("#{Rails.root}/app/views/index/about.html.erb")
      render
      return
    when 'POST'
      f = File.open("#{Rails.root}/app/views/index/about.html.erb", "w+")
      f << params[:text]
      f.close
      flash.now[:success] = "saved the new text"
      @text = File.read("#{Rails.root}/app/views/index/about.html.erb")
      render
      return
    end
  end

  def edit_help
    case request.method
    when 'GET'
      @text = File.read("#{Rails.root}/app/views/index/help.html.erb")
      render
      return
    when 'POST'
      f = File.open("#{Rails.root}/app/views/index/help.html.erb", "w+")
      f << params[:text]
      f.close
      flash.now[:success] = "saved the new text"
      @text = File.read("#{Rails.root}/app/views/index/help.html.erb")
      render
      return
    end
  end
end
