2.times do
  fork do
    sleep 10
  end
end

Process.waitall
