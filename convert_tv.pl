use strict;
use warnings;
no warnings;
#
our $GUBED = 0;  #debug levels for Paul Eatons code.  0 disables as well

my $myFile = $ARGV[0];
# print "$myFile \n";



my $origFileArrRef = ReadInDataFile($myFile); 
my @origFileArr    = @{$origFileArrRef};
my @outputNewFileArr;

my @levelArrayBits; 
my @checkArrayBits;
my @directionArrayBits;

my @levelArrayHex; 
my @checkArrayHex;
my @directionArrayHex;


my $state = "lookingForStart";
my $lineCounter ; 
while (@origFileArr) {
  my $nextLine = shift(@origFileArr);
  #my $origFileArrSize = scalar(@origFileArr);
  my $dataline = Strip($nextLine);  
  my $thisTextLine = $dataline;
  my @lineBitsArr = split(/\s+/,$thisTextLine);
  my $count = scalar(@lineBitsArr);
  
  if ($lineBitsArr[0] eq "***"){
	  #skip for a comment line
	  next;
  }
  
  
  if ($count == 0) {
     #skip empty lines.
     next;
  }
  
  $lineCounter++;
  # print "parsing line $lineCounter : $nextLine \n";

  if      ($state eq "lookingForStart") {
   print "$count \n"; 
   if ($count > 1) {
    if ($lineBitsArr[0] eq "001") {
       #push @outputNewFileArr, $nextLine;
       $state = "go_time" ;
    } else {
       #push @outputNewFileArr, $nextLine;
    } 
   } else {
      #do nothing  
   }
  } 



  if ($state eq "go_time") {
     $lineBitsArr[0] = "";
     my $thisTestVector = join ("", @lineBitsArr);
     my @thisTestVectorArray = split ("", $thisTestVector);
     my $tvNum = scalar(@thisTestVectorArray);
     for(my $i=0; $i<$tvNum; $i++ ) {
        my $thisBit = $thisTestVectorArray[$i];
        if ($thisBit eq "-") {
           #print "minus!  that means to drive this pin to 0. \n";
           $checkArrayBits[$i]     = 0; # 0 = dont check this bit
           $directionArrayBits[$i] = 0; # 0 = Output, drive from FPGA to DUT
           $levelArrayBits[$i]     = 0; # 0 = drive to 0
           # print "";
        }
        if ($thisBit eq "+") {
           #print "plus!  that means to drive this pin to 1. \n";
           $checkArrayBits[$i]     = 0; # 0 = dont check this bit
           $directionArrayBits[$i] = 0; # 0 = Output, drive from FPGA to DUT
           $levelArrayBits[$i]     = 1; # 1 = drive to 1
           # print "";
        }

        if ($thisBit eq "1") {
           #print "one!  that means to check that this pin driven by DUT is a 1. \n";
           $checkArrayBits[$i]     = 1; # 1 = check this bit
           $directionArrayBits[$i] = 1; # 1 = input, drive from DUT to FPGA 
           $levelArrayBits[$i]     = 1; # 1 = check the value is 1
           # print "";
        }
        if ($thisBit eq "0") {
           #print "zero!  that means to check that this pin driven by DUT is a 0. \n";
           $checkArrayBits[$i]     = 1; # 1 = check this bit
           $directionArrayBits[$i] = 1; # 1 = input, drive from DUT to FPGA 
           $levelArrayBits[$i]     = 0; # 0 = check the value is 0
           # print "";
        }
        if ($thisBit eq "X") {
           #print "X!  nobody cares!!!! \n";
           $checkArrayBits[$i]     = 0; # 0 = dont check this bit
           $directionArrayBits[$i] = 1; # 1 = input, drive from DUT to FPGA 
           $levelArrayBits[$i]     = 0; # 0 = can be 0 or 1 as long as the checkarray bit is 0 it wont be checked.
           # print "";
        }

        #print "$i  $thisBit \n";
        # print "";
     }  #end of for loop, creating ArrayBits
     ####################################################################################################################
     ####################################################################################################################
     ####################################################################################################################
     my $checkHexString     = MakeHexString(\@checkArrayBits);
     my $directionHexString = MakeHexString(\@directionArrayBits);
     my $levelHexString     = MakeHexString(\@levelArrayBits);
     # print "";  
     ####################################################################################################################
     ####################################################################################################################
     ####################################################################################################################
     # push @outputNewFileArr, "P";
     push @outputNewFileArr, "C"."$checkHexString";
     #push @outputNewFileArr, "C0000000000000000000000000000";  # zero out line, no checks.  for testing.
     # push @outputNewFileArr, "P";
     push @outputNewFileArr, "D"."$directionHexString";
     # push @outputNewFileArr, "P";
     push @outputNewFileArr, "L"."$levelHexString";
     push @outputNewFileArr, "S1";
     # push @outputNewFileArr, "P";
     # print "";  
  } #go_time
} # while (@origFileArr)   
  
  


#while (@xtraArr) {
#  my $nextLine = shift(@xtraArr);
#  push @outputNewFileArr, $nextLine;
#}
#



my $outputNetlist = 'modified.txt';
# print "creating datafile: ".$outputNetlist." \n";
SaveDataFile($outputNetlist, \@outputNewFileArr);


print "OK \n";
(1);



  
sub MakeHexString {
   my $bitArrayRef = shift;
   my @bitArray    = @{$bitArrayRef};
  
   my @hexArray;
   # print "done creating bit files, converting to hex values. \n";
   # print "";
   #combine sets of 4 bits into nibbles
   #allowing for up to 112 IO pins in the test vector == 28 sets of 4
   #put the 28 nibbles together to create the command that will be sent through the UART
   
   for(my $i=0; $i<28; $i++ ) {
      my $i1= $i*4 + 0;  #index 1
      my $i2= $i*4 + 1;  #index 2
      my $i3= $i*4 + 2;  #index 3
      my $i4= $i*4 + 3;  #index 4
   
      my $nibbleVal =     $bitArray[$i1] * 1 +       $bitArray[$i2] * 2 +       $bitArray[$i3] * 4 +       $bitArray[$i4] * 8 ;      
      my $nibble = $nibbleVal;
      if ($nibbleVal == 10) {$nibble = "A"}
      if ($nibbleVal == 11) {$nibble = "B"}
      if ($nibbleVal == 12) {$nibble = "C"}
      if ($nibbleVal == 13) {$nibble = "D"}
      if ($nibbleVal == 14) {$nibble = "E"}
      if ($nibbleVal == 15) {$nibble = "F"}
      # print "nibble = $nibble \n";      
      unshift(@hexArray,     $nibble);
      # print "";   
   }
   
   my $hexString = join("", @hexArray);
   return $hexString;
   
}






######################################################################
######################################################################
######################################################################
##############################
### HANDLE LOG file information
##############################
sub CalculateCurrentTime {
   my ($sec,$min,$hour,$day,$month,$yr19,@rest) =   localtime(time);#######To get the localtime of your system
   #calculate current time/day
   my $timeText = "";
   $timeText .= "\n\n\n";
   $timeText .= "Date:\t$day-".++$month. "-".($yr19+1900)."\n"; ####To priint dat+e format as expected
   $timeText .= "Time:\t".sprintf("%02d",$hour).":".sprintf("%02d",$min).":".sprintf("%02d",$sec)."\n";###To priint the current time
   my $GUBEDText = $timeText;
   GUBEDLINE($GUBEDText,9);
   # 
   $yr19 += 1900;
   $GUBEDText = " $sec \n $min \n $hour \n $day \n $month \n $yr19 \n\n\n ";
   GUBEDLINE($GUBEDText,9);
   return ($sec,$min,$hour,$day,$month,$yr19);
}

######################################################################
## my $dataFromDataDumperStoredInFileRef = WriteDataDumperFile($datFileName, $dumperDataStructRef)
sub WriteDataDumperFile {
   my $datFileName      = shift;  #write to file, datadumper file
   my $dumperDataStructRef = shift;
   my $writeSuccessflag = 1; 
   #following is from perl book:
   if (-e $datFileName) {
      print "$datFileName already exists, going to try deleting the file first? \n";
      unlink($datFileName);
   } else {
   }
   open (FILE, ">".$datFileName."") or die "can't open $datFileName  $!";
   print FILE Data::Dumper->Dump([$dumperDataStructRef], [qw (dumperDataStructRef)]);  #when eval runs on during the readdatadumperfile, the structure will be recreated under the referencename $dumperDataStruct
   close FILE                       or die "can't close tvinfo: $!";
   #
   return $writeSuccessflag;   
}

######################################################################
## my $dataFromDataDumperStoredInFileRef = ReadInDataDumperFile($datFile)
sub ReadInDataDumperFile {
   my $datFileName         = shift;
   #
   #include at top=>use File::Find;
   #include at top=>use File::Basename;
   #include at top=>use Data::Dumper qw(Dumper); #print Dumper(\\%hash);  # note the \ backslash; Dumper() takes references as arguments
   #include at top=>$Data::Dumper::Purity = 1;       # since %TV is self-referential
   #following is from perl book:
   #         
   #from programming perl,                           #alternate method, not currently used=> do "filename.ext"            or die "can't recreate tvinfo: $! $@";
   #http://docstore.mik.ua/orelly/perl4/prog/ch09_07.htm     
   open (FILE, "".$datFileName."") or die "can't open tvinfo: $!";
   #any way to store $/ so it can be reset once this function is complete?
   local $/ = undef;                # read whole file
   my $dumperDataStructRef;  #this will match the name originally created?
   eval <FILE>;                     # recreate the datastructure, down to the name.  need a common name to use, and then transfer into a reference to return from this subroutine
   die  "can't recreate tv data from tvinfo.perldata: $@" if $@;
   close FILE                       or die "can't close tvinfo: $!";
   return $dumperDataStructRef;   
}

######################################################################
##GUBEDLINE($GUBEDText, $GUBEDLevel);        
sub GUBEDLINE {
   my $GUBEDText  = shift;
   my $GUBEDLevel = shift;
   #
   print "$GUBEDText" if ($GUBED > $GUBEDLevel);
   return 1;   
}

######################################################################
##$dataFileRef   = ReadInDataFile($datFile);        
sub ReadInDataFile {
   my $datFileName = shift;
   my @nextDataSet ;
   open(IN,$datFileName) || die "cannot open $datFileName for reading: $!";
   while (<IN>) {
      my $dataline = $_ ;
      next unless($dataline);
      $dataline = Strip($dataline);
      push @nextDataSet, $dataline;
   }
   close(IN);
   return \@nextDataSet;   
}
######################################################################
sub SaveDataFile {
   my $datFileName  = shift ;
   my $dataArrayRef = shift ;
   open(OUT, ">".$datFileName."") || die "cannot open $datFileName for writing: $!";
   print OUT join("\n", @{$dataArrayRef});
   close(OUT);
   return ;
}
######################################################################
sub Strip {
  my $tmp = shift;
  $tmp =~  s/^\s+//;           # trim leading whitespace
  $tmp =~  s/\s+$//;           # trim trailing whitespace
  $tmp =~ s#\s+# #g;    
  return $tmp;
}   
######################################################################
sub Remove_0x {
  my $tmp = shift;
  $tmp =~  s/^0x//i;           
  return $tmp;
}   
######################################################################
sub NoSpaces {
  my $tmp = shift;
  $tmp =~  s/^\s+//;           # trim leading whitespace
  $tmp =~  s/\s+$//;           # trim trailing whitespace
  $tmp =~ s#\s+##g;    
  return $tmp;
}   




#  } elsif ($parsingStatus eq "copying_subckts" ) {
#     print "hi \n";
#  } else {
#     print "warning, code is neither \"looking_for_first_subckt\" NOR \"copying_subckts\" \n";
#     print "what is parsingStatus of:".$parsingStatus.": ?\n";
#  }
