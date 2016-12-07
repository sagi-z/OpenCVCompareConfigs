#!/usr/bin/perl

open IN, $ARGV[0] or die;
$colIdx=0;
$numDataRows=0;
while (<IN>)
{
    # Analyzing the <table>
    if (/^\s*<table class="tbl">/ ... /^\s*<\/table>/)
    {
        # Get the table columns we're intereseted in from the <thead>
        if (/^\s*<thead/ ... /<\/thead>/)
        {
            if (/<th[^e]/ ... /<\/th>/)
            {
                if (/x-factor/)
                {   # This column tells how faster/slower this build is
                    $name=$_;
                    $name=~s@<br/>@ @g;
                    $name=~s/\svs\s.*$//;
                    $name=~s/^\s*//;
                    chomp($name);
                    $data{$colIdx}->{name}=$name;
                    $data{$colIdx}->{val}=0;
                }
                $colIdx++ if /<\/th>/;
            }
        }

        # Get the rest form the <tbody>
        # Accumulate the data for the columns we're intereseted in
        # and count data rows for average
        if (/^\s*<tbody>/ ... /^\s*<\/tbody>/)
        {
            if (/<tr/)
            {
                $col=0;
                ++$numDataRows;
            }
            $col++ if /<\/td>/;
            if (exists $data{$col})
            {
                if (/^\s*([\d.]+)\s*$/)
                {
                    $val=$1;
                    $data{$col}->{val} += $val;
                }
                elsif (/^\s*-\s*$/)
                {
                    $val=1;
                    $data{$col}->{val} += $val;
                }
            }
        }
    }
}

# Calcluate average
for $key (keys %data)
{
    $data{$key}->{val} /= $numDataRows;
}

# Print sorted
@sorted_keys=sort {$data{$b}->{val} <=> $data{$a}->{val}} keys %data;
for $key (@sorted_keys)
{
    print sprintf "%.3f times faster for '$data{$key}->{name}'\n", $data{$key}->{val};
}

close IN
