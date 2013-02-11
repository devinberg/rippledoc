# Rippledoc

Produces html docs from markdown files (using
[Pandoc](http://johnmacfarlane.net/pandoc/) for the heavy lifting).
It's expected that the pandoc-markdown files are arranged in
usefully-name subdirectories.

Rippledoc also generates a not-especially-ordered table of contents
for you.

Rippledoc is written in Perl 5.


# What it does

Given this:

    docs/
        index.md
        foo/
            bar.md
            baz.md
            moo/
                aa.md
                bb.md
        zz.md

Rippledoc produces this:

    docs/
        index.md
        index.html
        toc.md
        toc.html
        foo/
            bar.md
            bar.html
            baz.md
            baz.html
            moo/
                aa.md
                aa.html
                bb.md
                bb.html
        zz.md
        zz.html



# Example output

Some of [my own misc
notes](http://www.unexpected-vortices.com/misc-notes/index.html).



# Installation

Prerequisites:

  * A relatively recent Perl 5
  * The following Perl 5 modules: Modern::Perl File::Slurp
  * a fairly recent version of Pandoc

Just put the rippledoc.pl script somewhere on your PATH and
make sure it's executable (`chmod +x rippledoc.pl`).



# Usage

Run the script from a directory containing docs.



# The Rules

  * If you have a top-level file named "_copyright", rippledoc will
    include its contents in the footer of every generated html file.

  * You must have a top-level "index.md" file, and its first line
    must be like "`% Name of this doc project`".

  * All other .md files must have their first line be like
    "`% Title of this doc`".

  * Don't create a toc.md file. This program takes care of that, and
    if you create one it will be overwritten.



# Caveats

  * Currently, this program doesn't provide any manual control of the
    ordering of items in the table of contents.



# License

Copyright 2013 John Gabriele

Distributed under the GNU GPL v3 or later (see COPYING for details).
