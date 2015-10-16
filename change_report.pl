use strict;
use warnings;
use List::Util qw( max );
use Spreadsheet::Read;
use Getopt::Long qw(:config bundling);
use Data::Dumper;

sub usage {
    my $err = shift and select STDERR;
    print "usage: $0 [--verbose[=1]] file.xls file.xlsx\n";
    exit $err;
}    # usage

my $opt_v = 1;
GetOptions(
    "help|?"      => sub { usage(0); },
    "v|verbose:2" => \$opt_v,
) or usage(1);

my $file1 = shift or usage(1);
my $file2 = shift or usage(1);

binmode STDOUT, ":encoding(utf-8)";

my $ss1 = ReadData($file1) or die "Cannot read $file1: $!\n";
my $ss2 = ReadData($file2) or die "Cannot read $file2: $!\n";

# Only looking at sheet #1 in each spreadsheet:
my $s1 = $ss1->[1];
my $s2 = $ss2->[1];

#printf "Files compared:\n$file1: Sheet '%s' = %5d cols x %5d rows\n$file2: Sheet '%s' = %5d cols x %5d rows\n",
#   $s1->{label}, $s1->{maxcol}, $s1->{maxrow},
#   $s2->{label}, $s2->{maxcol}, $s2->{maxrow};

# Extract the periods (e.g. '2014Q4') from the filenames:
my ($period1) = ($file1 =~ m{(\d\d\d\dQ\d)});
my ($period2) = ($file2 =~ m{(\d\d\d\dQ\d)});

# First, get the population of column headers and their indexes for the first spreadsheet:
my %column_map = ();
my %dc_map = ();

my @r1_f1 = Spreadsheet::Read::row( $s1, 1 );
my @r1_f2 = Spreadsheet::Read::row( $s2, 1 );

# Construct a map for cross-referencing columns:
foreach my $c ( 0 .. $s1->{maxcol} ) {
    add_to_map( \%column_map, $r1_f1[$c], $c + 1, $file1);
}
foreach my $c ( 0 .. $s2->{maxcol} ) {
    add_to_map( \%column_map, $r1_f2[$c], $c + 1, $file2);
}

# And also map where each Data Center ID is in each file:
my $key_col_name = 'Data Center ID';
my $f1_key_col = $column_map{$key_col_name}{$file1};
my $f2_key_col = $column_map{$key_col_name}{$file2};

# Get the full ID column from each sheet:
my @dc_f1 = @{$s1->{cell}[$f1_key_col]};
my @dc_f2 = @{$s2->{cell}[$f2_key_col]};

# Start at 2 to skip headers:
foreach my $r ( 2 .. $s1->{maxrow} ) {
   add_to_map( \%dc_map, $dc_f1[$r], $r, $file1);
}
foreach my $r ( 2 .. $s2->{maxrow} ) {
    add_to_map( \%dc_map, $dc_f2[$r], $r, $file2);
}

sub add_to_map {
    my ($hr, $c_n, $c_i, $filename) = @_;
    # nothing to store if the cell name is blank:
    return unless $c_n;

    if (exists $hr->{$c_n}) {
        $hr->{$c_n}{$filename} = $c_i;
    } else {
        $hr->{$c_n} = { $filename => $c_i };
    }
    return;
}


# OK, now we know which rows go with which across the two files, even if they've moved.

# Time to compare:
my @diffs = ();
print "Data Center ID, Field, Period1, Value1, Period2, Value2, Change\n";

# Loop through each Data Center ID, fetch that specific row wherever it is in the sheet:
foreach my $dc_id (keys %dc_map) {
    my $f1_row = $dc_map{$dc_id}{$file1};
    my $f2_row = $dc_map{$dc_id}{$file2};
    my @r1 = Spreadsheet::Read::row( $s1, $f1_row );
    my @r2 = Spreadsheet::Read::row( $s2, $f2_row );

    # Loop through the column names & compare the specific cells for each:
    foreach my $cname (keys %column_map) {
        my $f1_col = $column_map{$cname}{$file1};
        my $f2_col = $column_map{$cname}{$file2};
         
        # Get the actual cells in question:
        my $c1 = $r1[$f1_col];
        my $c2 = $r2[$f2_col];
        if ( defined $c1 ) {
            if ( defined $c2 ) {
                # If they match (stringwise), move on:
                next if $c1 eq $c2;

                # Otherwise print the differing values:
                my $delta = $c2 - $c1;
                print "$dc_id, $cname, $period1, $c1, $period2, $c2, $delta\n";
                next;
            }
            #warn "COMPARING $f1_col,$f1_row TO $f2_col,$f2_row";
            print "($dc_id, $cname)\t $file1 $c1 ... -- undefined -- $file2\n";
            next;
        }
        # if both are undefined, also skip:
        defined $c2 or next;

        #warn "COMPARING $f1_col,$f1_row TO $f2_col,$f2_row";
        print "($dc_id, $cname)\t$file1 -- undefined -- ... $c2 $file2\n";
    }
}
