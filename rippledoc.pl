#!/usr/bin/env perl

use Modern::Perl;
use autodie qw/:all/;
use File::Slurp;
use File::Basename;
use File::Find;

# Rippledoc: a simple Pandoc-markdown doc processing tool.
#
# Copyright 2013 John Gabriele <jgabriele@fastmail.fm>.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

say "=== Rippledoc, 2013-02-13 ===";

if (! -e 'index.md') {
    die "Couldn't find an index.md file here.\n" .
      "Are you at the top of your docs directory?\n" .
      "If so, create an index.md and try again.\n";
}
if (! -e 'styles.css') {
    say "Couldn't find a styles.css file here. Creating one...";
    create_default_styles_file();
}

my $project_name = get_title_for('index.md');
say qq{Generating docs for "$project_name".};

my $copyright = '&nbsp;';
if (-e '_copyright') {
    $copyright = read_file('_copyright');
}

say "Creating the toc file...";

{
    open my $toc_file, '>', 'toc.md';
    say {$toc_file} <<'EOT';
% Table of Contents

EOT
    find(
        sub {
            my $dir = $File::Find::dir;  # The dir we're *in*.
            my $full_name = $File::Find::name;
            unless ( m/^[\w.-]+$/ ) {
                die "Please use only letters, numbers, dots, dashes,\n" .
                  "and underscores in directory and file names.\n" .
                  qq{Culprit is "$File::Find::name". Exiting.\n};
            }
            my $list_marker = '  * ';
            my $depth = find_depth($dir);
            my $indent = q{    } x $depth;

            if (-d and $_ ne '.') {
                say {$toc_file} $indent .
                  $list_marker .
                  "[$_/]($File::Find::name/toc.html)";
                create_mini_toc_here($File::Find::name);
            }
            elsif (-f and m/\.md$/ and $_ ne 'toc.md' and
                                       $_ ne 'index.md') {
                my $html_fn = $full_name;
                $html_fn =~ s/\.md$/.html/;
                my $title = get_title_for($_);
                say {$toc_file} $indent . $list_marker . "[$title]($html_fn)";
            }
        },
        '.'
    );
    say {$toc_file} '';
    close $toc_file;
}

# Process all md files.
find(
    sub {
        if (-f and m/\.md$/) {
            my $md_filename = $_;
            my $html_filename = $md_filename;
            $html_filename =~ s/\.md$/.html/;
            my $depth = find_depth($File::Find::dir);
            my $prefix = '../' x $depth;
            if (! -e $html_filename or
                  (stat $md_filename)[9] > (stat $html_filename)[9]) {
                create_temp_header_footer_files($File::Find::name);
                my $pandoc_command = "pandoc -s -S --mathjax " .
                  "--css=${prefix}styles.css -B /tmp/before.html " .
                    "-A /tmp/after.html -o $html_filename $md_filename";
                unless ($md_filename eq 'toc.md') {
                    say "Processing $File::Find::name ...";
                }
                system $pandoc_command;
            }
        }
    },
    '.'
);

# Main is done.

# ======================================================================
# Gets called while in dirs that `find` has brought us to. Is
# passed directory names beginning with './' (ex. './' and './foo/bar').
sub create_mini_toc_here {
    my ($full_path_of_dir) = @_;
    my $unq_name = basename $full_path_of_dir;
    $full_path_of_dir =~ s{^\./}{};
    chdir $unq_name;
    my @things_here = glob '*';
    open my $toc_file, '>', 'toc.md';
    say {$toc_file} qq{% Contents of "$full_path_of_dir"\n};
    for (@things_here) {
        if (-d) {
            say {$toc_file} "  * [$_/]($_/toc.html)";
        }
        elsif (-f and m/\.md$/ and $_ ne 'toc.md') {
            my $h = $_;
            $h =~ s/\.md$/.html/;
            my $t = get_title_for($_);
            say {$toc_file} "  * [$t]($h)";
        }
    }
    close $toc_file;
    chdir '..';
}

# Header goes just after `<body>`. Footer goes just before `</body>`.
# $doc_path comes in looking like: './a.md', './b/c.md', './d/e/f.md', etc.
sub create_temp_header_footer_files {
    my ($doc_path) = @_;
    $doc_path =~ s{^\./}{};

    my $link_path_prefix = '../' x find_depth($doc_path);

    my $basename = basename $doc_path;
    $basename =~ s/\.md$/.html/;

    my $dirname  = dirname $doc_path;
    my $breadcrumb_trail = '';

    if ($dirname eq '.') {
        $breadcrumb_trail .= $basename;
    }
    else {
        my @dirnames = split m{/}, $dirname;
        @dirnames = reverse @dirnames;
        # We reverse them because we want to start with the dir
        # that the file is in, and then as we go further up, our
        # links to little's toc's have more '../'s in them.

        my @linkified_dirnames = ();
        my $count = 0;
        for (@dirnames) {
            push @linkified_dirnames,
              qq{<a href="} . ('../' x $count) . qq{toc.html">$_</a>};
            $count++;
        }

        @linkified_dirnames = reverse @linkified_dirnames;

        $breadcrumb_trail .= join '/', @linkified_dirnames;
        $breadcrumb_trail .= "/$basename";
    }

    my $nav_bar_html = <<"EOT";
<a href="${link_path_prefix}index.html">Home</a> &nbsp;
  <a href="${link_path_prefix}toc.html">ToC</a> &nbsp;&nbsp;
  (This is: $breadcrumb_trail)
EOT
    open my $before, '>', '/tmp/before.html';
    say {$before} <<"EOT";
<div id="indtopbar">email: berg1786@umn.edu | &copy; 2008 - 2013 Devin R. Berg | <a href="http://www.linkedin.com/in/devinberg"><img src="http://devinberg.com/images/logos/linkedin.png" alt="linkedin logo"/></a> <a href="http://plus.google.com/u/0/106130596573742041459/posts"><img src="http://devinberg.com/images/logos/gplus.png" alt="Google+ logo"/></a> </div>
<div id="indwrapper">

	<div id="navbar">
		<ul id="navlist">
			<li><a href="http://www.devinberg.com">About</a></li>
			<li><a href="http://www.devinberg.com/vita">Vita</a></li>
			<li><a href="http://www.devinberg.com/articles" style="background-color: #FFF; color: #000;">Articles</a></li>
			<li><a href="http://www.devinberg.com/publications">Publications</a></li>
			<li><a href="http://www.devinberg.com/projects">Projects</a></li>
		</ul>
	</div>
<div id="content">
<div id="nav-bar-top">
  $nav_bar_html
</div>
<div id="content-box">
EOT
    open my $after, '>', '/tmp/after.html';
    say {$after} <<"EOT";
</div> <!-- /content-box -->
<div id="nav-bar-bottom">
  $nav_bar_html
</div>
<div id="box-footer">
  <div id="copyright">$copyright</div>
  <div id="generated-by">Generated by
    <a href="https://github.com/devinberg/rippledoc">Rippledoc</a>
    (with behind-the-scenes help from
    <a href="http://johnmacfarlane.net/pandoc/">Pandoc</a>).</div>
</div>
</div> <!-- /main-box -->
</div> <!-- /content -->
EOT
    close $before;
    close $after;
}

sub find_depth {
    my ($full_pathname) = @_;
    my $depth = $full_pathname =~ tr{/}{};
    return $depth;
}

sub get_title_for {
    my ($fn) = @_;
    my @lines = read_file($fn, {chomp => 1});
    my $title = $lines[0];
    unless ($title =~ s/^% //) {
        die "Couldn't find a title block in $fn. Please add one. Exiting.\n";
    }
    return $title;
}

sub create_default_styles_file {
    open my $styles_file, '>', 'styles.css';
    print {$styles_file} <<'EOT';
body {
    text-align: center;
    min-width: 760px;
    background: #333333;
}

#main-box {
    width: 800px;
    margin: 20px auto;
}

div#indwrapper {
    margin: 0 auto;
    margin-top: 30px;
    width: 760px;
    background: #333333;
    overflow:hidden	
}

div#content a:hover {
    text-decoration: underline;
}

div#indtopbar {
    height: 75px;
    font-family: trebuchet ms,arial,verdana;
    font-size: 8pt;
    font-weight: normal;
    text-align: center;
    padding-top: 10px;
    margin: 0 auto;
    color: #ffffff;
    letter-spacing: 1.1pt;
    clear: both;
}

div#indtopbar a {
    color: #ffffff;
    font-weight: bold;
    text-decoration: none;
}

div#indtopbar a:hover {
    text-decoration: underline;
}

#navbar ul
{
        padding: 0;
        margin: 0;
	font-family: trebuchet ms,arial,verdana;
        float: right;
        width: 100%;
}

#navbar ul li
{
        display: inline;
}

#navbar ul li a
{
        padding: 6px 10px;
        color: #FFF;
        text-decoration: none;
        float: right;
}

#navbar ul li a:hover
{
        background-color: #FFF;
        color: #000;
}

#design_navbar ul
{
        padding: 0;
        margin: 0;
	font-family: trebuchet ms,arial,verdana;
        float: left;
        width: 100%;
}

#design_navbar ul li
{
        display: inline;
}

#design_navbar ul li a
{
        padding: 6px 10px;
        color: #bbb;
        text-decoration: none;
        float: left;
}

#design_navbar ul li a:hover
{
        background-color: #eee;
		text-decoration: none;
        color: #000;
}

h1 {
    color: #000000;
    font-weight: bold;
    font-size: 15px;
}
div#content {
    clear: both;
    text-align: left;
    padding: 15px 15px 15px 15px;
    float: center;
    width: 730px;
    font-family: trebuchet ms,arial,verdana;
    font-size: 9pt;
    font-weight: normal;
    color: #000000;
    background: #ffffff;
}

html>body div#wrapper {
    height: 100%;
    min-height: 400px;
}

#box-header, #box-footer {
    color: #fff;
    background-color: #3D5A96;
    padding: 20px;
}

#box-header {
    font-family: sans-serif;
    font-size: xx-large;
    text-shadow: 1px 1px 2px #444;
    font-weight: bold;
    text-align: center;
}

#box-footer a:link, #box-footer a:visited, #nav-bar-top a:link, #nav-bar-top a:visited, #nav-bar-bottom a:link, #nav-bar-bottom a:visited {
    color: #fff;
}

#box-footer {
    font-size: small;
    font-style: italic;
}

#box-footer #generated-by {
    text-align: right;
}

/* Pandoc generates a #header div at the top for the main title.
   No particular styling here for that right now.
*/

/* Doc-specific toc that Pandoc generates for us. */
#TOC {
    background-color: #f0f6f0;
    border: 1px solid #e0e6e0;
}

#nav-bar-top, #nav-bar-bottom {
    color: #fff;
    font-size: small;
    font-family: sans-serif;
    background-color: #63B132;
    padding-left: 6px;
}

#nav-bar-top    {
    border-bottom: 2px solid #5BA12F;
    padding-top: 2px;
    padding-bottom: 2px;
}

#nav-bar-bottom {
    border-top: 2px solid #5BA12F;
    padding-top: 0px;
    padding-bottom: 4px;
}

#content-box {
    background-color: #fff;
    padding: 2px 20px 20px 20px;
}

.dirname-in-toc {
    font-weight: bold;
}

code {
    background-color: #f6f6f6;
}

pre {
    padding: 6px 2px 6px 6px;
    background-color: #f6f6f6;
    border: 1px solid #e8e8e8;
}

caption {
    font-style: italic;
    font-size: small;
    color: #555;
}

a:link {
    color: #3A4089;
}

a:visited {
    color: #875098;
}

table {
    background-color: #f6f6f6;
    border: 2px solid #d8d8d8;
    border-collapse: collapse;
    margin-left: auto;
    margin-right: auto;
}

th {
    background-color: #d8d8d8;
    padding-right: 4px;
}

tr, td, th {
    border: 2px solid #d8d8d8;
    padding-left: 4px;
    padding-right: 4px;
}

dt {
    font-weight: bold;
}

blockquote {
    color: #3a3a3a;
    background-color: #edf0fa;
    border: 1px solid #dde0ea;
    padding: 2px 16px 2px 16px;
}

blockquote code, blockquote pre {
    background-color: #dae2f4;
    border-style: none;
}

h1, h2, h3, h4, h5 {
    font-family: sans-serif;
}

h3, h5 {
    font-style: italic;
}

.spacer {
    padding-left: 40px;
}
EOT
    close $styles_file;
}
