require 'ajax_scaffold'

class Route < ActiveRecord::Base
  belongs_to :transport_session
  has_many :buses, :dependent => :destroy

  validates_presence_of :price
  validates_presence_of :display_order
  validates_numericality_of :display_order, :only_integer => true
  validates_length_of :point_a, :minimum => 1
  validates_length_of :point_b, :minimum => 1
  validates_presence_of :transport_session
  validates_associated :transport_session
  
  @scaffold_columns = [
    AjaxScaffold::ScaffoldColumn.new(self, {:name => "transport_session", 
                                            :eval => "route.transport_session.name", 
                                            :sort_sql => "transport_sessions.name",
                                            :label => "Transport Session"}),
    AjaxScaffold::ScaffoldColumn.new(self, {:name => "point_a",
                                            :label => "Home Point"}),
    AjaxScaffold::ScaffoldColumn.new(self, {:name => "point_b",
                                            :label => "Away Point"}),
    AjaxScaffold::ScaffoldColumn.new(self, {:name => "information",
                                            :label => "Route Info"}),
    AjaxScaffold::ScaffoldColumn.new(self, {:name => "price",
                                            :label => "Price ($)"}),
    AjaxScaffold::ScaffoldColumn.new(self, {:name => "display_order",
                                            :label => "Schedule Order"})
  ]

  def to_m
    return price.to_money
  end
  
  def readable_route
    return "(" + self.transport_session.name + ") " + self.point_a + " - " + self.point_b
  end

  def going_away_buses
    Bus.find(:all, :conditions => ["route_id = ? AND going_away = TRUE", self.id], :order => "departure ASC")
  end
  
  def coming_home_buses
    Bus.find(:all, :conditions => ["route_id = ? AND going_away = FALSE", self.id], :order => "departure ASC")    
  end
end
