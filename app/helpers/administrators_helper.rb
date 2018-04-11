module AdministratorsHelper
  # include AjaxScaffold::Helper

  def num_columns
    scaffold_columns.length + 1
  end

  def scaffold_columns
    Administrator.scaffold_columns
  end

  def buses_count_helper
    Bus.count
  end

  def route_count_helper
    Route.count
  end

  def transport_sessions_count_helper
    TransportSession.count
  end
end
