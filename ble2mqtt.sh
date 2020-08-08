#!/usr/bin/expect

# make this an input parameter once I have more than one sensor
set mac A4:C1:38:5E:90:39

# 20 seconds should be enough time to receive at least one transmission
set timeout 20

# don't want to see commands as they are executed...
log_user 0

# start up the bluetooth tool...
spawn gatttool -b $mac  --char-write-req --handle=0x0038 --value=0100 --listen

expect {
	timeout { exit 1}
	eof	{ exit 1}
	"Characteristic*\n"
}

expect {
	timeout { exit 1 }
	eof	{ exit 1 }
	"value: *\n"
}

set results $expect_out(0,string)
close $spawn_id

# first two bytes are temp*100 in LE format
scan [lindex $results 2] %x val_hi
scan [lindex $results 1] %x val_lo
set temp [expr [expr {$val_hi * 256 + $val_lo}] / 100.0]
puts "Temperature: ${temp}\'F"

# third byte is humidity
scan [lindex $results 3] %x humidity
puts "Humidity: ${humidity}%"

# forth and fifth bytes are battery voltage in millivolts and LE format
scan [lindex $results 5] %x val_hi
scan [lindex $results 4] %x val_lo
set batt [expr [expr {$val_hi * 256 + $val_lo}] / 1000.0]
puts "Battery: ${batt}V"

set json "{ \"temp\":$temp,\"humidity\":$humidity,\"batt\":$batt }"
exec /usr/bin/mosquitto_pub -h omv -t "xiaomi/den/value" -m $json
#exec /usr/bin/mosquitto_pub -h omv -t "xiaomi/den/temp" -m $temp
#exec /usr/bin/mosquitto_pub -h omv -t "xiaomi/den/humidity" -m $humidity
#exec /usr/bin/mosquitto_pub -h omv -t "xiaomi/den/batt" -m $batt

exit 0
