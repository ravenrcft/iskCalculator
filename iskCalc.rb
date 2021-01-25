require 'time'


incursionData = []

iskCalc = File.open("isk7.txt")
iskCalc.each do |line|
	packet = line.split("\t")

	if packet[1] == "Corporate Reward Payout"
		timestamp = Time.parse(packet[0].gsub('.','-') + " UTC").to_i

		if packet[2].include? ".00" # Remove cents
			reward = packet[2].gsub(".00", "").gsub(",","").gsub(" ISK","").to_i
		else
			reward = packet[2].gsub(",","").gsub(" ISK","").to_i
		end

		incursionData << [timestamp, reward]
	end 
end
iskCalc.close

if incursionData.count <= 1
	puts "Must be more than one timestamp"
	exit
end

ascendOrDescend = incursionData[0][0] - incursionData[1][0]
incursionData = incursionData.reverse if ascendOrDescend < 0

def elapse(elapsed)
	hours = elapsed / 3600
	minutes = elapsed / 60 - (hours * 60)
	seconds = elapsed - (minutes * 60) - (hours * 3600)

	if hours > 0
		if seconds < 10 && minutes < 10
			return "#{hours}:0#{minutes}:0#{seconds}"
		elsif seconds < 10 && minutes > 9
			return "#{hours}:#{minutes}:0#{seconds}"
		elsif seconds > 9 && minutes < 10
			return "#{hours}:0#{minutes}:#{seconds}"
		else
			return "#{hours}:#{minutes}:#{seconds}"
		end
	else
		if seconds < 10
			return "#{minutes}:0#{seconds}"
		else
			return "#{minutes}:#{seconds}"
		end
	end
end

def loyalty(iskArray)
	reward = {
		3500000 => 400,
		10395000 => 1400, 9615375 => 1295, 8783775 => 1183, 7900200 => 1064,
		18200000 => 3500, 16835000 => 3238, 15379000 => 2958,
		31500000 => 7000, 29137500 => 6475,
		63000000 => 14000
	}
	total = 0
	iskArray.each {|isk| total += reward[isk] if reward[isk] != nil}
	return total
end

def formatIsk(isk)
	return isk.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

previousData = 0
totalRewards = []
elapsedArray = []

incursionData.each do |data|
	totalRewards << data[1]

	if previousData != 0
		timelapse = previousData - data[0]
		data << elapse(timelapse)
		elapsedArray << timelapse
	end
	previousData = data[0]
end

incursionData.reverse.each do |data|
	puts "-" * 10
	puts Time.at(data[0]).gmtime
	puts "$#{formatIsk(data[1])}"
	puts "Time: #{data[2]}" if data[2] != nil
	puts "LP: #{formatIsk(loyalty([data[1]]))}"
end

totalIsk = totalRewards.inject{|sum, x| sum + x}
totalElapse = incursionData[0][0] - incursionData[incursionData.count - 1][0]
totalIskPerHours = (totalIsk / (totalElapse / 3600.00)).to_i

puts "-" * 10
puts "Total isk/hour $#{formatIsk(totalIskPerHours)}"
puts "Total Time: #{elapse(totalElapse)}"
puts "-" * 10
puts "Total isk $#{formatIsk(totalIsk)}"
puts "Total isk w/ LP $#{formatIsk((loyalty(totalRewards) * 1100) + totalIsk)}"
puts "LP Earned: #{formatIsk(loyalty(totalRewards))}"
puts "-" * 10
puts "Min: #{elapse(elapsedArray.min)}" 
puts "Max: #{elapse(elapsedArray.max)}"
puts "Avg: #{elapse(elapsedArray.inject{|sum, el| sum + el} / elapsedArray.size)}"
