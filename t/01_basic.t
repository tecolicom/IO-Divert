use strict;
use warnings;
use utf8;
use Encode ();
use Test::More;
use IO::Divert;

subtest 'basic capture and autoprint' => sub {
    my $output = '';
    {
	local *STDOUT;
	open STDOUT, '>', \$output;
	{
	    my $d = IO::Divert->new;
	    print "Hello\n";
	}
    }
    is $output, "Hello\n", 'output captured and printed';
};

subtest 'FINAL callback' => sub {
    my $output = '';
    {
	local *STDOUT;
	open STDOUT, '>', \$output;
	{
	    my $d = IO::Divert->new(FINAL => sub { s/^/> /mg });
	    print "Line1\n";
	    print "Line2\n";
	}
    }
    is $output, "> Line1\n> Line2\n", 'FINAL callback applied';
};

subtest 'autoprint => 0' => sub {
    my $output = '';
    my $captured;
    {
	local *STDOUT;
	open STDOUT, '>', \$output;
	{
	    my $d = IO::Divert->new(autoprint => 0);
	    print "captured";
	    $captured = $d->content;
	}
    }
    is $output, '', 'no autoprint';
    is $captured, 'captured', 'content retrieved';
};

subtest 'content method' => sub {
    my $content;
    {
	local *STDOUT;
	open STDOUT, '>', \my $dummy;
	{
	    my $d = IO::Divert->new(autoprint => 0);
	    print "test";
	    $content = $d->content;
	}
    }
    is $content, 'test', 'content method works';
};

subtest 'clear method' => sub {
    my $output = '';
    {
	local *STDOUT;
	open STDOUT, '>', \$output;
	{
	    my $d = IO::Divert->new;
	    print "first";
	    $d->clear;
	    print "second";
	}
    }
    is $output, 'second', 'clear works';
};

subtest 'UTF-8 handling' => sub {
    my $output = '';
    {
	local *STDOUT;
	open STDOUT, '>:encoding(utf-8)', \$output;
	{
	    my $d = IO::Divert->new;
	    print "日本語\n";
	}
    }
    is Encode::decode('utf-8', $output), "日本語\n", 'UTF-8 handled correctly';
};

done_testing;
