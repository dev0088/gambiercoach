class Money
  include Comparable

  attr_reader :cents

  class MoneyError < StandardError# :nodoc:
  end

  def initialize(cents)
    @cents = cents
  end

  def eql?(other_money)
    cents == other_money.cents
  end

  def <=>(other_money)
    cents <=> other_money.cents
  end

  def +(other_money)
    return other_money.dup if cents.zero? 
    return dup if other_money.cents.zero?

    Money.new(cents + other_money.cents)
  end

  def -(other_money)
    Money.new(cents - other_money.cents)
  end

  # get the cents value of the object
  def cents
    @cents.to_i
  end

  # multiply money by fixnum
  def *(fixnum)
    Money.new(cents * fixnum)    
  end

  # divide money by fixnum
  def /(fixnum)
    Money.new(cents / fixnum)    
  end
  
  # Test if the money amount is zero
  def zero?
    cents == 0 
  end

  def to_s
    sprintf("$%.2f", cents.to_f / 100  )
  end

  # Create a new money object with value 0
  def self.empty()
    Money.new(0)
  end

  # Conversation to self
  def to_money
    self
  end  
end