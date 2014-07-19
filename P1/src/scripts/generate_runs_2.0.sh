#!/usr/bin/perl -w

if ($#ARGV != 1) {
    print STDERR "generate_runs.pl <number of processes> <size(K)>\n";
    exit(0);
} else {
    $processes = $ARGV[0];
    $size      = $ARGV[1];
}   

@operations=("READ", "WRITE");
@arrivaltimes=(0,2,10,100);
@inst=(20,50,100,300);

print STDOUT "<ProcessInfo>\n";
$pid=0;
$arrival=0;
$ni=0;
$at=0;
$division=$processes/4; 

for  ($processes_it=1;$processes_it<=$processes;$processes_it++) {  
    print STDOUT "          <Process>\n";
    print STDOUT "                <Id>$pid</Id>\n";
    print STDOUT "                <ArrivalTime>$arrivaltimes[$at]</ArrivalTime>\n";
    $dataSize = $size - $inst[$ni];
    print STDOUT "                <DataSize>$dataSize</DataSize>\n";
    print STDOUT "                <Instructions> \n";
    for ($inst_it=0;$inst_it<$inst[$ni];$inst_it++){
	print STDOUT "                      <Operation>\n";	
#        $r= int rand(1,$size);
        $p = $size - $inst[$ni];
        $r= int rand($p) + $inst[$ni];
	print STDOUT "                             <AccessedAddress>$r</AccessedAddress>\n";
#	$r1=rand(0,2);
	$r1=rand(2);
	print STDOUT "                             <InstructionType>$operations[$r1]</InstructionType>\n";
	print STDOUT "                      </Operation>\n";	
    }
    print STDOUT "                </Instructions>\n";
    print STDOUT "          </Process>\n";
    $pid++;
    $arrival++;
    if ($processes_it%$division == 0) {$at++;}
    $ni++;
    if ($ni == 4) {$ni=0;}
}
print STDOUT "</ProcessInfo>";


