# makes a basic string HTML/Javascript-safe, escaping ' and "
def hs(text)
  text.gsub!("'","&#39;")
end

# offers time in convenient Excel format
def time_string(the_time)
  return the_time.strftime("%Y_%m_%d %H:%M")
end