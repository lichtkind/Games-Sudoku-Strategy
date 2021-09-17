#!/usr/bin/perl -w

use Wx qw[:allclasses];
use Benchmark;
use strict;

Apfel->new->MainLoop;

package Apfel;

use base qw(Wx::App);
use Wx::Event qw (EVT_BUTTON);

sub OnInit {
    my $t1 = new Benchmark;
    my $frame = Wx::Frame->new( undef, -1, "Apfelmaennchen", [-1,-1], [1000,1000]);

    my $Button = Wx::Button->new($frame,-1,"Malen",[450,850],[100,50]);
    my $panel = Wx::Panel->new( $frame, -1, [0,0],[1000,800]);
    my $dc = $frame->{dc} = Wx::MemoryDC->new();
    $frame->{tafel} = Wx::StaticBitmap->new( $panel, -1, Wx::Bitmap->new( 0, 0, -1), [100,1]);
    $dc->Clear();
    EVT_BUTTON($frame,$Button, \&malen($frame));     
    $frame->Show(1);
    print " fertsch:",Benchmark::timestr( Benchmark::timediff( new Benchmark, $t1 ) ), "\n";
}


sub malen {
   my $frame = shift;
   my $n = 50;   
   my @punkt;
   my $data;
   my ($width,$height) = (800,800);
   
   for my $i (1..$width){
      my $y = $i/200 - 2;
      for my $j (1..$height){
         my $x = $j/200 - 2;
         ${$punkt[$i]}[$j] = &iterieren($x,$y,$n);
         $data .= ${$punkt[$i]}[$j] < 51
            ? pack('C3',0,5*${$punkt[$i]}[$j],5*${$punkt[$i]}[$j])
            : pack('C3',0,255,255) ;
      }
   }
   
   my $bmp = data_to_pixmap($data,$width,$height);
   $frame->{tafel}->SetBitmap( $bmp );
   $frame->{dc}->SelectObject( $bmp );
   $frame->{tafel}->Refresh();
}   
  
sub data_to_pixmap {
  my ($data,$width,$height) = @_;
  my $wximg = Wx::Image->new( $width, $height, $data );
  return Wx::Bitmap->new($wximg);
}

sub iterieren {
   my $x1 = $_[0]; my $xN = 0;
   my $y1 = $_[1]; my $yN = 0;
   my $count = 0;
   my $a;
   for my $i (1..$_[2]){
      my $xNplus = $xN**2 - $yN**2 + $x1;
      my $yNplus = 2 * $xN * $yN + $y1;
      $a = $xNplus**2 + $yNplus**2;
      $xN = $xNplus;
      $yN = $yNplus;
      if ($a > 4){$count = $i; last;}
   }
   return $count;
}

