Screen
=========

** Note that while Screen was a cool idea, it could not handle *interactive* command-line programs due to issues with piping.  Screen is currently mostly disabled.  You may view the website, but you can't interact much with the server.


The Screen website can be viewed [here](http://learnnation.org/screen.html)!

You can read a little about Screen [here](http://learnnation.org/screen-about).



check that stuff is flushing.



old server kick-off directions:
--------------------------------------

export PERL5LIB=."${PERL5LIB:+:$PERL5LIB}" && perl mojo.pl daemon -l http://privateIP:5432

that is, put the CURRENT directory as the first place to search for modules, then launch the program via mojolicious, serve it as the Private IP address under the AWS allowed port, and then it can be visited at the public IP address...

http://54.186.113.49:5432




new FreeBSD server kick-off (http://www.daemonology.net/freebsd-on-ec2/) directions:
----------------------------------------------------------------

su root  
sh

PERL5LIB=.  
export PERL5LIB=/home/freebsd/Library/Perl/5.16/Downloads"${PERL5LIB:+:$PERL5LIB}"  
export PERL5LIB=/home/freebsd/Library/Perl/5.16/Downloads/darwin-thread-multi-2level"${PERL5LIB:+:$PERL5LIB}"  
export PERL5LIB=/home/freebsd/Library/Perl/5.16/Custom"${PERL5LIB:+:$PERL5LIB}"  
export PERL5LIB=/home/freebsd/Library/Perl/5.16/Custom/darwin-thread-multi-2level"${PERL5LIB:+:$PERL5LIB}"  

perl mojo.pl daemon -l http://192.241.177.163:8000

use the PRIVATE IP ADDRESS (not public, and not localhost)



FreeBSD 11.1 digital ocean server kick-off directions:
---------------------------------------------------------

sudo pkg install git  
git clone this project  
cd into this project  
sh  
cpan  
cpan install Mojolicious::Lite  
cpan install Time::Stamp  
PERL5LIB=.  
perl mojo.pl daemon -l http://PRIVATEIP:8000  
alternatively, try hypnotoad mojo.pl


