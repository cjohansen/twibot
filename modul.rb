module TestM
  def self.included(mod)
    @@inst = 0
  end

  def yeah
    puts "Yeah! #{@@inst}"
    @@inst += 1
  end
end

include TestM
yeah
yeah
puts @@inst
