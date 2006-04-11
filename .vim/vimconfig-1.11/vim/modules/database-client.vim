" Vim database client (Perl::DBI)
"
" File:			database-client.vim
" Maintainer:	Lubomir Host 'rajo' <rajo AT platon.sk>
" Version:		$Platon: vimconfig/vim/modules/database-client.vim,v 1.8 2005/03/09 19:50:15 rajo Exp $
"
" Copyright (c) 2003-2005 Platon SDG, http://platon.sk/
" Licensed under terms of GNU General Public License.
" All rights reserved.
"
" $Platon: vimconfig/vim/modules/database-client.vim,v 1.8 2005/03/09 19:50:15 rajo Exp $
" 

" This plugin needs Perl interpreter to be enabled (+perl feature)
if ! has('perl')
	echo "You don't have perl"
	finish
endif

echo "sourcing DBI client ..."

"---------------------------------------------------------------------------
"------------------------ USER CONFIGURABLE OPTIONS ------------------------
"---------------------------------------------------------------------------
" Set default values:
if !exists('g:SQL_main_window_title')
    let g:SQL_main_window_title = "SQL"
endif
if !exists('g:SQL_data_window_title')
    let g:SQL_data_window_title = "SQL_data"
endif
if !exists('g:SQL_cmd_window_title')
    let g:SQL_cmd_window_title = "SQL_log"
endif

" width of main window
if !exists('g:SQL_main_window_width')
	"let g:SQL_main_window_width = 20
	let g:SQL_main_window_width = 39
endif
" height of command window
if !exists('g:SQL_cmd_window_height')
	let g:SQL_cmd_window_height = 10
endif

" Control whether additional help is displayed as part of the taglist or not.
" Also, controls whether empty lines are used to separate the tag tree.
if !exists('g:SQL_Compact_Format')
    let g:SQL_Compact_Format = 0
endif


" Default SQL command on startup
if !exists('g:SQL_last_command')
    let g:SQL_last_command = "SELECT * FROM table"
endif

"---------------------------------------------------------------------------
"-------------------- END OF USER CONFIGURABLE OPTIONS ---------------------
"---------------------------------------------------------------------------

" Initialize the SQL plugin local variables for the supported file types
" and tag types

" Are we displaying brief help text
let s:sql_brief_help = 1

" Include the empty line displayed after the help text
let s:brief_help_size = 2
let s:full_help_size = 4


" autosource this file on write
augroup DBIclient
	autocmd!
	autocmd BufWritePost database-client.vim source ~/.vim/modules/database-client.vim
augroup END

" initialize DBI engine
function! SQL_Init() " {{{
	perl << EOF

	use Time::HiRes qw(gettimeofday tv_interval);
	use POSIX qw(strftime);
	use Env;
	use DBI;

	package DBI::st;

	# fetch and print data from _executed_ DBI statement handler
	sub dump_data ($$)
	{ # {{{
		my ($sth, $curbuf) = @_;

		# if buffer is not defined, dump data to current window
		unless (defined $curbuf) {
			$curbuf = $main::curbuf;
		}

		my $numFields     = $sth->{'NUM_OF_FIELDS'};
		my $column_names  = $sth->{'NAME'};
		my $column_sizes  = $sth->{'mysql_max_length'};
		my $column_is_num = $sth->{'mysql_is_num'};

		# build column name's line
		my $header_names = "";
		foreach (my $i = 0; $i < $numFields; $i++) {
			# numeric columns have smaller length as column name, overwrite ...
			$$column_sizes[$i] = $$column_sizes[$i] > length($$column_names[$i])
				? $$column_sizes[$i]
				: ($$column_is_num[$i] ? -1 : 1) * length($$column_names[$i]); # WARN: negative length! - used for right aligment of numbers
			$header_names .= sprintf("%s%s", $i ? " | " : "| ", $$column_names[$i] . " " x ($$column_sizes[$i] - length($$column_names[$i])));
		}
		$header_names .= " |";

		# build header separator
		my $separator = "";
		foreach (my $i = 0; $i < $numFields; $i++) {
			$separator .= "+" . ("-" x (abs($$column_sizes[$i]) + 2));
		}
		$separator .= "+"; # the end

		# print header
		$curbuf->Append($curbuf->Count(), $separator, $header_names, $separator);

		# print data
		while (my @row = $sth->fetchrow_array()) {
			my $line = "";
			foreach (my $i = 0; $i < $numFields; $i++) {
				$line .= sprintf("%s%s", $i ? " | " : "| ",
					$$column_sizes[$i] > 0 # usage of negative length
						? $row[$i] . " " x ($$column_sizes[$i] - length($row[$i]))
						: " " x (- $$column_sizes[$i] - length($row[$i])) . $row[$i]
				);
			}
			$curbuf->Append($curbuf->Count(), "$line |");
		}

		# print footer
		$curbuf->Append($curbuf->Count(), $separator);

	} # }}}

	package main;

	# list of available database drivers
	@available_drivers = reverse sort DBI->available_drivers; # make "mysql" first!

	# return reference to array with database names
	sub SQL_database_list($;)
	{ # {{{
		my ($dbh) = @_;

		my $sth = $dbh->prepare("SHOW DATABASES");
		unless (defined $sth) {
			VIM::Msg("Error", $dbh->errstr);
			return;
		}
		$sth->execute();
		my @arr;

		while (my @row = $sth->fetchrow()) {
			push @arr, $row[0];
		}

		return \@arr;

	} # }}}

	sub SQL_add_database_list($$;)
	{ # {{{
		my ($key, $line) = @_;

		my $added_lines = 0;
		foreach my $db (@{ $main::connections->{$key}->{databases} }) {
			$main::curbuf->Append($line + $added_lines, "    " . $db);
			$added_lines++;
		}
		
	} # }}}
	
	# number of executed SQL commands
	my $sql_cmd_num = 0;

EOF
endfunction
" }}}

" Initialize NOW!
call SQL_Init()

" connect to database
" :call SQL_Connect("database_type", "server", "user", "password")
function! SQL_Connect(...) " {{{


	perl << EOF
	
	package main;

	my $param_count = VIM::Eval("a:0"); # number of function parameters
	my ($db_type, $db_host, $db_user, $db_pass);

	if ($param_count == 0) { # {{{ check for db_type
		my ($success, $value) = VIM::Eval("confirm('Please, choose type of database server: ', "
			. " '\&" . join("\n&", @main::available_drivers) . "\n')");
		if ($success and $value ne '') {
			$db_type = $main::available_drivers[--$value];
		}
		else {
			return;
		}
	}
	else {
		$db_type = VIM::Eval("a:1"); # get first function parameter
	} # }}}
	if ($param_count < 2) { # {{{ check for db_host
		# get hostname from user
		$db_host = "localhost" unless (defined $db_host); # remember server name
		my ($success, $value) = VIM::Eval("inputdialog('Hostname of your database server: ', '$db_host')");
		#VIM::Msg("success = $success value = $value");
		if ($success and $value ne '') {
			$db_host = $value;
		}
		else {
			return;
		}
	}
	else {
		$db_host = VIM::Eval("a:2"); # get second function parameter
	} # }}}
	if ($param_count < 3) { # {{{ check fro db_user
		# get username from user
		$db_user = $ENV{"USER"} unless (defined $db_user); # remember username
		my ($success, $value) = VIM::Eval("inputdialog('Login: ', '$db_user')");
		if ($success and $value ne '') {
			$db_user = $value;
		}
		else {
			return;
		}
	}
	else {
		$db_host = VIM::Eval("a:3");
	} # }}}
	if ($param_count < 4) { # {{{ check for db_pass
		# get password from user
		my ($success, $value) = VIM::Eval('inputsecret("Password: ")');
		if ($success) {
			$db_pass = $value;
		}
		else {
			return;
		}
		}
	else {
		$db_host = VIM::Eval("a:4");
	} # }}}


	$dbh = DBI->connect("DBI:$db_type:host=$db_host", $db_user, $db_pass,
		{ RaiseError => 0, AutoCommit => 1});
	unless (defined $dbh) {
		VIM::Msg("Error", $DBI::errstr);
		return;
	}
	# reconnect to database if the connection is lost
	if ($db_type =~ m/^mysql$/i) {
		$dbh->{mysql_auto_reconnect} = 1;
	}
	
	my $key   = "$db_host; $db_user;";
	my $ext   = "";
	my $index = 2;
	while (exists %main::connections->{"$key$ext"}) {
		$ext = " ($index)";
		$index++;
	}
	$key .= $ext; # add number of the same connection

	if (defined $dbh) {
		$main::connections->{$key} = {
			'dbh'	=> $dbh,
			'type'	=> $db_type,
			'desc'	=> "$db_user\@$db_host$ext [$db_type]",
			'list_databases'	=> 1,
			'databases'	=> SQL_database_list($dbh),
		};
		$main::current_conn = $key;
	}
	else {
		undef $main::connections->{$key};
	}
	undef $key, $ext, $index; # cleanup

	my $count = 0;
	foreach my $key (sort keys %{$main::connections}) {
		$count++;
		# reorder connections
		$main::connections->{$key}->{order} = $count;
	}
	undef $count; # cleanup
		
	VIM::Msg("Connect to database succsesfull");

EOF
	call s:SQL_UpdateDatabaseList()

endfunction
" }}}

" show used connections
function! SQL_ShowConnections() " {{{
	perl << EOF

	package main;

	my $count = 0;
	unless (scalar(keys %{$main::connections})) {
		VIM::Msg("No connections");
		return;
	}
	VIM::Msg("Active connections to database:");
	foreach my $key (sort keys %{$main::connections}) {
		$count++;
		# reorder connections
		$main::connections->{$key}->{order} = $count;
		VIM::Msg("$count - $main::connections->{$key}->{desc}");
	}

EOF
endfunction
" }}}

" disconnect from given connection
function! SQL_Disconnect() " {{{

	" use vertical layout of buttons
	let s:save_guioptions = &guioptions
	set guioptions+=v

	perl << EOF
	use DBI;

	package main;

	my $count = 0;
	my $choices = "";
	foreach my $key (sort keys %{$main::connections}) {
		$count++;
		# reorder connections
		$main::connections->{$key}->{order} = $count;
		$choices .=  '&' . "$count - $main::connections->{$key}->{desc}" . '\n';
	}
	#$choices =~ s/\\n$//g;
	$choices .= "&Cancel";
	if ($count == 0) {
		VIM::Msg("No connections...");
		return;
	}
	my ($success, $value) = VIM::Eval('confirm("From which database do you wish to disconnect?", "'
			. $choices . '", 1, "Question")');

	return unless ($value > 0);
	my $count = 0;
	foreach my $key (sort keys %{$main::connections}) {
		$count++;
		if ($count == $value) {
			$main::connections->{$key}->{dbh}->disconnect()
				or warn "Can't disconnect from database #$count: " . $DBI::errstr;
			undef $main::connections->{$key}->{dbh};
			delete $main::connections->{$key};
		}
	}

EOF

	let &guioptions = s:save_guioptions

	call s:SQL_UpdateDatabaseList()

endfunction
" }}}

" get SQL command from user and execute
function! SQL_Execute() " {{{
	
	let sql_cmd = inputdialog('SQL command:', g:SQL_last_command)
	if sql_cmd != ''
		call SQL_Do(sql_cmd)
	endif
	unlet sql_cmd
	
endfunction
" }}}

" execute SQL command
function! SQL_Do(sql_cmd) " {{{

	perl << EOF

	package main;

	my $dbh = $main::connections->{$main::current_conn}->{dbh};
	my $sql_cmd = VIM::Eval("a:sql_cmd"); # get function parameter from Vim to Perl

	# remove empty chars from beginning and end of string
	# add semilon at the end
	$sql_cmd =~ s/^\s+//g;
	$sql_cmd =~ s/[;\s]{1,}$//g;
	$sql_cmd = $sql_cmd . ";";

	# remember last SQL command
	VIM::DoCommand('let g:SQL_last_command="' . $sql_cmd . '"');

	$main::sql_cmd_num++;

	my ($success, $value)	= VIM::Eval("bufwinnr(g:SQL_cmd_window_title)");
	my ($cmd_window)		= $success ? VIM::Windows($value) : undef;
	my $cmd_buf				= $cmd_window ? $cmd_window->Buffer() : $main::curbuf;

	my ($success, $value)	= VIM::Eval("bufwinnr(g:SQL_data_window_title)");
	my ($data_window)		= $success ? VIM::Windows($value) : undef;
	my $data_buf			= $data_window ? $data_window->Buffer() : $main::curbuf;

	# add SQL cmd separator
	$data_buf->Append($data_buf->Count(),
		"", "-- Commnad #$main::sql_cmd_num: " . scalar localtime, $sql_cmd);
	$cmd_buf->Append($cmd_buf->Count(),
		"", "-- Commnad #$main::sql_cmd_num: " . scalar localtime, $sql_cmd);

	my $start_time = [ Time::HiRes::gettimeofday ];
	my $sth = $dbh->prepare($sql_cmd);
	if ($dbh->errstr) {
		$cmd_buf->Append($cmd_buf->Count(), "-- ERROR: " . $dbh->errstr);
	}
	else {
		$sth->execute();
		if ($dbh->errstr) {
			$cmd_buf->Append($cmd_buf->Count(), "-- ERROR: " . $dbh->errstr);
		}
		else {
			$sth->dump_data($data_buf);
			$data_buf->Append($curbuf->Count(),
				"-- " . $sth->rows() . " rows in set (" . Time::HiRes::tv_interval($start_time) . " sec)");	
			$sth->finish();
		}
	}
	#$cmd_window->Cursor($cmd_buf->Count(), 1);

	undef $cmd_window, $data_window;
	undef $cmd_buf, $data_buf;

EOF

	" get number of current window
	let curwinnum = bufwinnr('%')

	let winnum = bufwinnr(g:SQL_cmd_window_title)
	if winnum < 0 " window doesn't exists
		return
	endif
	
	" toggle to SQL window, scroll to end, and then switch back
	execute "normal \<c-w>" . winnum . "w"
	execute "normal G"
	execute "normal \<c-w>" . curwinnum . "w"

endfunction
" }}}

"create menu
function! SQL_CreateMenu() " {{{
	" remove whole menu 
	silent! aunmenu SQL
	amenu 200.10 S&QL.&Connect :call SQL_Connect()<Return>
	amenu 200.20 S&QL.&Disconnect :call SQL_Disconnect()<Return>
	amenu 200.30 S&QL.&Execute :call SQL_Execute()<Return>
	amenu 200.40.10 S&QL.&Show.&connections :call SQL_ShowConnections()<Return>
	amenu 200.40.20 S&QL.&Show.&databases :call SQL_Do('SHOW DATABASES')<Return>
	amenu 200.40.30 S&QL.&Show.&tables :call SQL_Do('SHOW TABLES')<Return>
	amenu 200.40.40 S&QL.&Show.&variables :call SQL_Do('SHOW VARIABLES')<Return>
	amenu 200.40.50 S&QL.&Show.&server\ status :call SQL_Do('SHOW STATUS')<Return>
	amenu 200.50.10 S&QL.&Windows.&create :call SQL_CreateWindows()<Return>
endfunction
" }}}
call SQL_CreateMenu()

" create windows
function! SQL_CreateWindows() " {{{
	let s:main_winnum = bufwinnr(g:SQL_main_window_title)
	call s:CloseWindow(s:main_winnum)
	
	let s:data_winnum = bufwinnr(g:SQL_data_window_title)
	call s:CloseWindow(s:data_winnum)
	
	let s:cmd_winnum  = bufwinnr(g:SQL_cmd_window_title)
	call s:CloseWindow(s:cmd_winnum)

	execute 'topleft split ' . g:SQL_cmd_window_title
	setlocal noswapfile
	setlocal buftype=nowrite
	setlocal bufhidden=delete
	setlocal nonumber
	setlocal wrap
	setlocal norightleft
	setlocal foldcolumn=0
	setlocal modifiable
	setlocal filetype=sql_log


	execute g:SQL_main_window_width " vsplit " . g:SQL_main_window_title
	setlocal noswapfile
	setlocal buftype=nowrite
	setlocal bufhidden=delete
	setlocal nonumber
	setlocal nowrap
	setlocal norightleft
	setlocal foldcolumn=0
	setlocal modifiable
	setlocal filetype=sql_menu
	call s:SQL_Display_Help()

	let s:winnr_SQL_cmd = bufwinnr(g:SQL_cmd_window_title)
	" switch to SQL_cmd window
	if s:winnr_SQL_cmd
		execute "normal \<c-w>" . s:winnr_SQL_cmd . "w"
	endif
	let s:vheight = winheight(s:winnr_SQL_cmd) - g:SQL_cmd_window_height
	if s:vheight > 0
		execute s:vheight . ' split ' . g:SQL_data_window_title
	else
		execute ' split ' . g:SQL_data_window_title
	endif
	
	setlocal noswapfile
	setlocal buftype=nowrite
	setlocal bufhidden=delete
	setlocal nonumber
	setlocal nowrap
	setlocal norightleft
	setlocal foldcolumn=0
	setlocal modifiable
	setlocal filetype=sql_data

	call s:Map_SQL_mappings()
	call s:SQL_UpdateDatabaseList()

endfunction
" }}}
"call CreateWindows()

" SQL_Display_Help() " {{{
" Function from taglist.vim plugin
" (Author: Yegappan Lakshmanan (yegappan AT yahoo DOT com)
function! s:SQL_Display_Help()

	if s:sql_brief_help
		" Add the brief help
		call append(0, "\" Press 'h' to display help text")
		call append(1, '')
	else
		" Add the extensive help
		call append(0, '" u : Update table list')
		call append(1, '" U : Update database list')
		call append(2, '" h : Remove help text')
		call append(3, '')
	endif
endfunction
" }}}

" s:CloseWindow() {{{
function! s:CloseWindow(winnum)
	" if window exists
	if a:winnum >= 0
		execute "normal \<c-w>" . a:winnum . "w"
		silent! close
	endif
endfunction
" }}}

" s:SQL_Toggle_Help_Text() {{{
" Toggle SQL plugin help text between the full version and the brief
" version
" Function from taglist.vim plugin
" (Author: Yegappan Lakshmanan (yegappan AT yahoo DOT com)
function! s:SQL_Toggle_Help_Text()
	if g:SQL_Compact_Format
		" In compact display mode, do not display help
		return
	endif

	setlocal modifiable

	" Set report option to a huge value to prevent informational messages
	" while deleting the lines
	let old_report = &report
	set report=99999

	" Remove the currently highlighted tag. Otherwise, the help text
	" might be highlighted by mistake
	match none

	" Toggle between brief and full help text
	if s:sql_brief_help
		let s:sql_brief_help = 0

		" Remove the previous help
		exe '1,' . s:brief_help_size . ' delete _'

		" Adjust the start/end line numbers for the files
		"call s:SQL_Update_Line_Offsets(0, 1, s:full_help_size - s:brief_help_size)
	else
		let s:sql_brief_help = 1

		" Remove the previous help
		exe '1,' . s:full_help_size . ' delete _'

		" Adjust the start/end line numbers for the files
		"call s:SQL_Update_Line_Offsets(0, 0, s:full_help_size - s:brief_help_size)
	endif

	call s:SQL_Display_Help()

	" Restore the report option
	let &report = old_report

	setlocal nomodifiable
endfunction
" }}}

" s:Map_SQL_cmd_mappings() {{{
function! s:Map_SQL_mappings()
	" get number of current window
	let curwinnum = bufwinnr('%')
	
	let winnum = bufwinnr(g:SQL_main_window_title)
	if winnum >= 0 " if window exists
		" toggle to SQL window and then back
		execute "normal \<c-w>" . winnum . "w"

		" toggle between long and short help format
		inoremap <buffer> <silent> h <C-o>:call <SID>SQL_Toggle_Help_Text()<CR>
		nnoremap <buffer> <silent> h :call <SID>SQL_Toggle_Help_Text()<CR>

		inoremap <buffer> <silent> U <C-o>:call <SID>SQL_UpdateDatabaseList()<CR>
		nnoremap <buffer> <silent> U :call <SID>SQL_UpdateDatabaseList()<CR>

		inoremap <buffer> <silent> <CR> <C-o>:call <SID>SQL_SwitchCurrentDB()<CR>
		nnoremap <buffer> <silent> <CR> :call <SID>SQL_SwitchCurrentDB()<CR>

		execute "normal \<c-w>" . curwinnum . "w"
	endif

	let winnum = bufwinnr(g:SQL_cmd_window_title)
	if winnum >= 0 " if window exists
		" toggle to SQL window and then back
		execute "normal \<c-w>" . winnum . "w"

		" execute current SQL command
		inoremap <buffer> <silent> <F9> <C-o>:call SQL_Do(getline("."))<CR>
		nnoremap <buffer> <silent> <F9> :call SQL_Do(getline("."))<CR>

		execute "normal \<c-w>" . curwinnum . "w"
	endif

	let winnum = bufwinnr(g:SQL_data_window_title)
	if winnum >= 0 " if window exists
		" toggle to SQL window and then back
		execute "normal \<c-w>" . winnum . "w"

		" execute current SQL command
		inoremap <buffer> <silent> <F9> <C-o>:call SQL_Do(getline("."))<CR>
		nnoremap <buffer> <silent> <F9> :call SQL_Do(getline("."))<CR>

		execute "normal \<c-w>" . curwinnum . "w"
	endif

endfunction
" }}}

" s:SQL_UpdateDatabaseList() {{{
function! s:SQL_UpdateDatabaseList()

	" get number of current window
	let curwinnum = bufwinnr('%')
	
	let winnum = bufwinnr(g:SQL_main_window_title)
	if winnum < 0 " window doesn't exists
		return
	endif
	
	" toggle to SQL window and then back
	execute "normal \<c-w>" . winnum . "w"

	setlocal modifiable

	" remove all lines after help lines
	if s:sql_brief_help
		silent! execute (s:brief_help_size + 1) . ',$ delete _'
	else
		silent! execute (s:full_help_size + 1) . ',$ delete _'
	endif

	perl << EOF

	package main;

	my $count = 0;
	foreach my $key (sort keys %{$main::connections}) {
		$count++;
		# reorder connections
		my $conn = $main::connections->{$key};
		$conn->{order} = $count;
		$main::curbuf->Append($main::curbuf->Count(),
			($conn->{list_databases} ?
				($main::current_conn eq $key ? '* ' : '+ ' ) :
				'- ')
			. $conn->{desc}
		);
		if ($conn->{list_databases}) {
			SQL_add_database_list($key, $main::curbuf->Count());
		}
	}

	if ($count == 0) { # No connections
		$main::curbuf->Append($main::curbuf->Count(), '" -- No connections');
	}

EOF

	setlocal nomodifiable
	execute "normal \<c-w>" . curwinnum . "w"

endfunction
" }}}

" s:SQL_SwitchCurrentDB() {{{
function! s:SQL_SwitchCurrentDB()

	" get number of current window
	let curwinnum = bufwinnr('%')
	
	let winnum = bufwinnr(g:SQL_main_window_title)
	if winnum < 0 " window doesn't exists
		return
	endif

	" toggle to SQL window and then back
	execute "normal \<c-w>" . winnum . "w"

	setlocal modifiable
	let curr_line = line(".")
	silent! execute "%s/^\*/+/g"
	silent! execute "normal " . curr_line . "G"

	" search for new active connection
	if match(getline("."), "^[+-]") == -1
		let linenum = search("^[+-]", "bW") " first search backward
	else " current line matches connection
		let linenum = curr_line
	endif
	if linenum == 0 " search also forward (if we are on top)
		let linenum = search("^[+-]", "W")
	endif
	if linenum == 0 " no db found, return
		return
	endif
	let curr_db = getline(linenum)
	call setline(linenum, substitute(curr_db, "^.", "*", ""))

	perl << EOF

	package main;

	my $new_conn = VIM::Eval("curr_db");
	my $new_db   = VIM::Eval("getline(curr_line)");
	$new_conn =~ s/^..//g;
	$new_db   =~ s/^....//g;

	foreach my $key (keys %{$main::connections}) {
		if ($new_conn eq $main::connections->{$key}->{desc}) {
			$main::current_conn = $key;
			my $retval = $main::connections->{$key}->{dbh}->do("USE $new_db");
			last;
		}
	}
EOF

	silent! execute "normal " . curr_line . "G"

	setlocal nomodifiable
	execute "normal \<c-w>" . curwinnum . "w"

endfunction
" }}}

" Modeline {{{
" vim: ts=4
" vim600: fdm=marker fdl=0 fdc=3
" }}}

