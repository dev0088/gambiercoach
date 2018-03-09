class HourlyCron < ActiveRecord::Base

  def self.do_work
    # delete all the wait list reservations for buses that have already departed
    self.delete_wait_list_reservations_for_departed_buses

    # expire unused wait list openings
    self.expire_unused_wait_list_openings

    # send conductor bus lists at time specified in settings
    self.send_conductor_bus_lists

    # send conductor follow-ups
    self.send_conductor_followups

    # send payment reminders
    self.send_payment_reminders
  end

  def self.delete_wait_list_reservations_for_departed_buses
    buses = Bus.where("departure < ?", Time.now)
    buses.each do |b|
      b.wait_list_reservations.destroy_all
    end
  end

  # find all wait list reservations that had a spot held open for them, but that spot has expired
  def self.expire_unused_wait_list_openings
    wlrs = WaitListReservation.where("spot_opened_at IS NOT NULL AND spot_opened_at <= ?",
            Setting.earliest_valid_wait_list_opening)
    wlrs.each do |wlr|
      WaitListReservation.create(:bus_id => wlr.bus_id,
                                 :user_id => wlr.user_id,
                                 :spot_opened_at => nil)
      wlr.destroy
      wlr.bus.update_waiting_list
    end
  end

  # only do something when +/- 15 minutes of the daily reservations closing time
  # when that holds, find all buses that depart before midnight the following day
  # and send conductors their bus lists
  def self.send_conductor_bus_lists
    now = Time.now
    close = Setting.reservations_closing_time
    if ((close.hour == now.hour) && (now.min < 15)) || ((close.hour - 1 == now.hour) && (now.min > 45))
      tomorrow_start = now.midnight + 24.hours
      tomorrow_end = now.midnight + 48.hours
      buses = Bus.where("departure > ? AND departure < ?", tomorrow_start, tomorrow_end)

      buses.each do |bus|
        if bus.conductor.nil?
          Notifications.deliver_admin_report("NO CONDUCTOR SPECIFIED FOR A BUS WHEN BUS LISTS WERE SENT",
                                             bus.departure.strftime("%A, %B %d") + " / " + bus.starting_point + " <-> " + bus.ending_point + " / " + bus.departure.strftime("%I:%M %p"),
                                             Setting::ADMIN_EMAIL)
        else
          email_txt = "Bus: " + bus.departure.strftime("%A, %B %d") + " departing " + bus.starting_point + " for " + bus.ending_point + " at " + bus.departure.strftime("%I:%M %p") + "\n\n"
          email_txt << " res # -- student login id\n"
          email_txt << "---------------------------\n"
          bus.reservation_tickets.order("reservations.id ASC").includes(:reservation).each do |rt|
            for i in 0...rt.quantity
              email_txt << sprintf("%6u", rt.reservation.id)+" -- "+rt.reservation.user.login_id+"\n"
            end
          end
          subject = "Conductor bus list for " + bus.departure.strftime("%A, %B %d") +" "+ bus.departure.strftime("%I:%M %p") + " / " + bus.starting_point + "<->" + bus.ending_point
          Notifications.deliver_conductor_bus_list(subject,
                                                   email_txt,
                                                   bus.conductor.email)
        end
      end
    end
  end

  # send conductor follow-ups 2 hours after a bus departs
  # we're pulling up buses that departed between 2 1/4 hours ago and 1 3/4 hours ago
  def self.send_conductor_followups
    now = Time.now
    buses = Bus.where("departure < ? and departure > ?", now - 1.75.hours, now - 2.25.hours)
    buses.each do |b|
      tr = TripReport.setup(b)
      Notifications.deliver_student_conductor_followup(b.conductor, b)
    end
  end

  # only do something when +/- 15 minutes of the daily payment reminder time
  # send payment reminders for all unpaid reservations
  def self.send_payment_reminders
    now = Time.now
    rtime = Setting.daily_payment_reminder_time
    if ((rtime.hour == now.hour) && (now.min < 15)) || ((rtime.hour - 1 == now.hour) && (now.min > 45))
      Reservation.all_unpaid.each do |ur|
        Notifications.deliver_payment_reminder(ur.user, ur)
      end
    end
  end
end
