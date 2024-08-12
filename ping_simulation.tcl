# Create a Simulator instance
set ns [new Simulator]

# Assign colors for traffic differentiation
$ns color 1 Blue
$ns color 2 Red

# Open trace and NAM files
set ntrace [open ping_sim.tr w]
$ns trace-all $ntrace
set namfile [open ping_sim.nam w]
$ns namtrace-all $namfile

# Define the Finish procedure
proc finish {} {
    global ns ntrace namfile
    # Flush trace data and close files
    $ns flush-trace
    close $ntrace
    close $namfile
    # Execute the NAM animation
    exec nam ping_sim.nam &
    # Display the number of ping packets dropped
    puts "Number of ping packets dropped: "
    exec grep "^d" ping_sim.tr | cut -d " " -f 5 | grep -c "ping" &
    exit 0
}

# Create six nodes
for {set i 0} {$i < 6} {incr i} {
    set n($i) [$ns node]
}

# Connect nodes with duplex links
for {set j 0} {$j < 5} {incr j} {
    $ns duplex-link $n($j) $n([expr ($j+1)]) 0.1Mb 10ms DropTail
}

# Define the recv function for the Agent/Ping class
Agent/Ping instproc recv {from rtt} {
    $self instvar node_
    puts "Node [$node_ id] received ping response from $from with RTT $rtt ms"
}

# Create and attach Ping agents to n(0) and n(5)
set p0 [new Agent/Ping]
$p0 set class_ 1
$ns attach-agent $n(0) $p0

set p1 [new Agent/Ping]
$p1 set class_ 1
$ns attach-agent $n(5) $p1
$ns connect $p0 $p1

# Set queue size and monitor
$ns queue-limit $n(2) $n(3) 2
$ns duplex-link-op $n(2) $n(3) queuePos 0.5

# Create congestion with CBR traffic between n(2) and n(4)
set tcp0 [new Agent/TCP]
$tcp0 set class_ 2
$ns attach-agent $n(2) $tcp0

set sink0 [new Agent/TCPSink]
$ns attach-agent $n(4) $sink0
$ns connect $tcp0 $sink0

# Apply CBR traffic over TCP
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 500
$cbr0 set rate_ 1Mb
$cbr0 attach-agent $tcp0

# Schedule events
$ns at 0.2 "$p0 send"
$ns at 0.4 "$p1 send"
$ns at 0.4 "$cbr0 start"
$ns at 0.8 "$p0 send"
$ns at 1.0 "$p1 send"
$ns at 1.2 "$cbr0 stop"
$ns at 1.4 "$p0 send"
$ns at 1.6 "$p1 send"
$ns at 1.8 "finish"

# Run the simulation
$ns run
