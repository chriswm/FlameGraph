#!/usr/bin/perl -w
#
# stackcollapse-bpfmemleak.pl	collapse bpftrace samples into single lines.
#
# USAGE ./stackcollapse-bpftrace.pl infile > outfile
#
# Example input:
#
#[20:04:09] Top 10 stacks with outstanding allocations:
#        2000 bytes in 1 allocations from stack
#                domalloc2+0xe [a.out]
#                main+0x33 [a.out]
#                __libc_start_main+0xf3 [libc-2.28.so]
#                [unknown]
#        30000 bytes in 1 allocations from stack
#                domalloc3+0xe [a.out]
#                main+0x3a [a.out]
#                __libc_start_main+0xf3 [libc-2.28.so]
#                [unknown]
#        217008 bytes in 1507 allocations from stack
#                add_data+0x2c4 [a.out]
#                _process_main+0x7d [a.out]
#                start_thread+0xfe [libpthread-2.28.so]
#
# Example output:
#
# [unknown];__libc_start_main+0xf3[libc-2.28.so];main+0x33[a.out];domalloc2+0xe[a.out] 2000
# [unknown];__libc_start_main+0xf3[libc-2.28.so];main+0x3a[a.out];domalloc3+0xe[a.out] 30000
# _process_main+0x7d[a.out];add_data+0x2c4[a.out] 217008
#
# Copyright 2020.  All rights reserved.
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software Foundation,
#  Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#  (http://www.gnu.org/copyleft/gpl.html)
#

use strict;

my @stack = ();
my @output = ();
my $in_stack = 0;
my $mem_allocd = 0;
my $num_allocs = 0;

foreach (<>) {
  chomp;
  if (/[\t ]+([0-9]+) bytes in ([0-9]+) allocations from stack$/) {
#    print "FOUND:$_\n";
    if (!$in_stack) {
      $in_stack = 1;
    } else {
#      print "\nCOLLAPSED:\n";
#      print $output[-1];
      push(@output, join(';', reverse(@stack)) . " $mem_allocd\n");
      @stack = ();
    }
    $mem_allocd = $1;
    $num_allocs = $2;
#    print "FOUND $mem_allocd bytes in $num_allocs allocations.\n";
  } else {
    if (/stacks with outstanding allocations:$/) {
#      print "FOUND DUMP: $_\n";
      $in_stack = 0;
      @stack = ();
      @output = ();
    }
    if ($in_stack) {
      $_ =~ s/\s//g;
      if (length $_ > 0) {
        push(@stack, $_);
#        print "STACK: $_\n";
      } else {
#        print "EMPTY COLLAPSED:\n";
#        print $output[-1];
        push(@output, join(';', reverse(@stack)) . " $mem_allocd\n");
        @stack = ();
        $in_stack = 0;
      }
    } else {
#      print "DROPPED: $_\n";
    }
  }
}
if (@stack > 0) {
#  print "\nEND COLLAPSED:\n";
  push(@output, join(';', reverse(@stack)) . " $mem_allocd\n");
}
if (@output > 0) {
#  print "OUTPUT:\n";
  print @output;
}


