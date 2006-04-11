
# XXX XXX XXX  THIS IS A NEW FILE XXX XXX XXX

#!/usr/bin/perl -w

#
# @FILE_EXT@
#
# Developed by @AUTHOR@ <@EMAIL@>
# Copyright (c) @YEAR@ @COMPANY@
# Licensed under terms of GNU General Public License.
# All rights reserved.
#
# Changelog:
# @DATE@ - created
#

# $Platon$

$|=1; 

use strict;

umask 022;


use lib qw( ./modules );
use FCGI;
use CGI::Lite;
use DBI qw(:sql_types);
use Template;
use Template::Plugin;
use Template::Exception;
use Time::HiRes qw(gettimeofday tv_interval); 
use Cwd;
use File::Basename qw( basename fileparse );


use vars qw (
	$cgi $req
	$dbh $data_source $database $db_host $db_user $db_password
	$runcount $runlimit
	$template

	$site_root $fastcgi_name
);

BEGIN
{
	$site_root = getcwd();

	my $hostname = `hostname`;

	# get name of FastCGI script
	my ($name, $path, $suffix) = fileparse($0, '.fcgi', '.cgi');
	$fastcgi_name = $name eq '' ? 'index' : $name; # default index

}

#
# Function declaration
#
sub to_ascii($;);

$data_source		= 'mysql';
$database			= 'my_database';
$db_user			= 'my_user';
$db_password		= 'my_secret_pass';

$cgi = CGI::Lite->new();
$req = FCGI::Request();

$template = Template->new({
	INCLUDE_PATH	=> './templates',
	AUTHOR			=> '@AUTHOR@',
	VARIABLES	=> {
		fastcgi_name	=> $fastcgi_name,
	},
});



# signal handlers {{{
local $SIG{ALRM}= sub { $req->LastCall(); };
local $SIG{SEGV}= sub { die "SIGSEGV received!!: $!"; };
local $SIG{TERM}= sub { $req->LastCall(); };
local $SIG{ABRT}= sub { $req->LastCall(); };
local $SIG{KILL}= sub { $req->LastCall(); };
local $SIG{XCPU}= sub { $req->LastCall(); };
local $SIG{XFSZ}= sub { $req->LastCall(); }; 
# }}}


#
# Connect to DB
#
$dbh = DBI->connect("dbi:$data_source:database=$database;host=$db_host", $db_user, $db_password)
	or die "Can't connect to $data_source: $DBI::errstr";


#
# MAIN:
#
# {{{
$runcount = 0;
$runlimit = 1000;
while ( ($runcount++ < $runlimit) && ($req->Accept() >= 0) ) {

	my %query;
	my %cookie;

	%query = $cgi->parse_new_form_data();
	%cookie = $cgi->parse_cookies(); 

	foreach (keys(%query)) { # simplify query if they are arrays
		$query{$_} = $query{$_}[0] if (ref $query{$_});
	} 		
	foreach (keys(%cookie)) { # simplify cookies if they are arrays
		$cookie{$_} = $cookie{$_}[0] if (ref $cookie{$_});
	} 


	if ($query{action} eq 'do_something') {
		MyPage(\%query);
	}
	# XXX:
	# XXX: Insert your code HERE !!
	# XXX:

 		
	if (-M $ENV{SCRIPT_FILENAME} < 0) { # Autorestart
		my $seconds = -86400.0 * -M  $ENV{SCRIPT_FILENAME};
		warn "FastCGI MODIFIED $seconds seconds after startup, restarting ...\n";# if ($globals::debug);
		$req->LastCall();
	}
	$req->Finish();

	undef %cookie;
	undef %query;

} # }}}


exit 0;

sub MyPage($;)
{ # {{{
	my ($ref_query) = @_;
	my	$template_data = {
		query		=> $ref_query,
	};

	$template->process('index.tt2', $template_data) or die $template->error(), "\n";

} # }}}


sub to_ascii($;)
{ # {{{
	my ($str) = @_;
	
	$str =~ tr/AÁÄBCÈDÏEÉÌËFGHIÍJKLÅ¼MNÒOÓÔÖPQRÀØSŠTUÚÙÜVWXYİZaáäbcèdïeéìëfghiíjklå¾mnòoóôöpqràøsštuúùüvwxyız/AAABCCDDEEEEFGHIIJKLLLMNNOOOOPQRRRSSTTUUUUVWXYYZZaaabccddeeeefghiijklllmnnoooopqrrrssttuuuuvwxyyzz/;

	return $str;

} # }}} 


# vim: ft=perl
# vim600: fdm=marker fdl=0 fdc=3

