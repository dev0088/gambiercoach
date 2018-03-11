class Notifications < ActionMailer::Base
  
  def admin_report(report_type, report_body, recipient)
    @subject    = "#{Setting::NAME} / Administrator Report / #{report_type}"
    @body       = {:report_body => report_body}
    @recipients  = "#{recipient}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = Time.now
    @header     = {}
  end
  
  def cash_reservation_create_success(user, reservation)
    @subject    = "#{Setting::NAME} / reservation complete / payment reminder"
    @body       = {:user => user, :reservation => reservation}
    @recipients  = "#{user.email}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = Time.now
    @header     = {}
  end
  
  def cc_reservation_create_success(user, reservation)
    @subject    = "#{Setting::NAME} / reservation and payment complete"
    @body       = {:user => user, :reservation => reservation}
    @recipients  = "#{user.email}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = Time.now
    @header     = {}
  end
  
  def change_password_success(user, sent_at = Time.now)
    @subject    = "#{Setting::NAME} / successfully changed your password"
    @body       = {:user => user}
    @recipients = "#{user.email}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = sent_at
    @headers    = {}    
  end
  
  def conductor_bus_list(subject, report_body, recipient)
    @subject    = "#{Setting::NAME} / #{subject}"
    @body       = {:report_body => report_body}
    @recipients  = "#{recipient}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = Time.now
    @header     = {}
  end

  def forgot_password(user, url, sent_at = Time.now)
    @subject    = "#{Setting::NAME} / forgot password instructions"
    @body       = {:user => user, :url => url}
    @recipients = "#{user.email}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = sent_at
    @headers    = {}
  end
  
  def payment_received(user, reservation)
    @subject    = "#{Setting::NAME} / payment received"
    @body       = {:user => user, :reservation => reservation}
    @recipients  = "#{user.email}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = Time.now
    @header     = {}    
  end
  
  def payment_reminder(user, reservation)
    @subject    = "#{Setting::NAME} / payment reminder"
    @body       = {:user => user, :reservation => reservation}
    @recipients  = "#{user.email}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = Time.now
    @header     = {}    
  end
  
  def reservation_modify_success(user, reservation)
    @subject    = "#{Setting::NAME} / reservation successfully modified"
    @body       = {:user => user, :reservation => reservation}
    @recipients = user.email
    @from = Setting::FROM_EMAIL
    @sent_on = Time.now
    @header = {}
  end
  
  def student_conductor_bus_list()
    @subject    = "#{Setting::NAME} / student conductor bus list"
    @body       = {:user => user, :reservation => reservation}
    @recipients  = "#{user.email}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = Time.now
    @header     = {}
  end

  def student_conductor_designation(user, bus)
    @subject    = "#{Setting::NAME} / you have been selected as a Student Conductor"
    @body       = {:user => user, :bus => bus}
    @recipients  = "#{user.email}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = Time.now
    @header     = {}
  end
  
  def student_conductor_followup(user, bus)
    @subject    = "#{Setting::NAME} / follow-up to complete student conductor refund"
    @body       = {:user => user, :bus => bus}
    @recipients  = "#{user.email}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = Time.now
    @header     = {}
  end

  def verify(login_id, token, email, sent_at = Time.now)
    @subject    = "#{Setting::NAME} / account verification"
    @body       = {:token => token, :login_id => login_id}
    @recipients = "#{email}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = sent_at
    @headers    = {}
  end
  
  def wait_list_spot_opened(user, bus)
    @subject    = "#{Setting::NAME} / WAIT LIST SPOT OPEN FOR YOU"
    @body       = {:user => user, :bus => bus}
    @recipients  = "#{user.email}"
    @from       = Setting::FROM_EMAIL
    @sent_on    = Time.now
    @header     = {}
  end

  def wait_list_success(user, wlr)
    @subject    = "#{Setting::NAME} / successfully reserved a spot on a wait list"
    @body       = {:user => user, :wlr => wlr, :bus => wlr.bus}
    @recipients = user.email
    @from = Setting::FROM_EMAIL
    @sent_on = Time.now
    @header = {}
  end  
  
  def reservation_modified_by_user(user, reservation_id, refund_amt)
    @subject    = "#{Setting::NAME} / credit to user necessary after modification"
    @body       = {:user => user, :r_id => reservation_id, :refund_amt => refund_amt}
    @recipients = Setting::ADMIN_EMAIL
    @from = Setting::FROM_EMAIL
    @sent_on = Time.now
    @header = {}    
  end
end
