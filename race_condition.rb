# frozen_string_literal: true

class BankAccount
  attr_accessor :balance

  def initialize
    @balance = 0
  end

  def deposit(amount)
    raise "can't deposit less than 0" if amount.negative?

    @balance += amount
  end

  def withdraw(amount)
    raise 'Insufficient funds' if balance < amount

    @balance -= amount
  end
end

class Atm
  def initialize(account)
    @account = account
  end

  def transaction
    @account.deposit(10)
    sleep(10)
    @account.withdraw(10)
  end
end

account = BankAccount.new
atms = (0..1000).map do |_i|
  Process.fork do
    Atm.new(account).transaction
  end
end
atms.each { |pid| Process.wait(pid) }

puts "Final balance: #{account.balance}"
