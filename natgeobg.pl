#!/usr/bin/env perl

use 5.010;
use strict;
use utf8;
use warnings FATAL => 'all';
use POSIX qw( uname );
use Mojo::UserAgent;

use constant DARWIN => 'darwin';

my $base_path = '/tmp/';
my $url
  = 'http://photography.nationalgeographic.com/photography/photo-of-the-day';

my $ua = Mojo::UserAgent->new;

my $img_url;
if ( $ua->get($url)->res->dom->at('div.download_link a') ) {
    $img_url = $ua->get($url)->res->dom->at('div.download_link a')->{href};
}
else {
    # use image preview if there's no link to a higher resolution image
    $img_url = $ua->get($url)->res->dom->at('div.primary_photo a img')->{src};
}

my $filename = $base_path . Mojo::Path->new($img_url)->parts->[-1];
$ua->get($img_url)->res->content->asset->move_to($filename);

set_wallpaper($filename);

exit 0;

sub set_wallpaper {
    my ($filename) = @_;

    my $os_name = lc $^O;

    given ($os_name) {
        when (/darwin/) {
            system("defaults write com.apple.desktop Background '{default = {ImageFilePath = $filename;};}'");
            system("killall Dock");
        }
        when (/linux/) {
            my $desk_env = lc $ENV{XDG_CURRENT_DESKTOP};
            given ($desk_env) {
                when (/gnome|unity/) {
                    system(
                        'gsettings',                    'set',
                        'org.gnome.desktop.background', 'picture-uri',
                        "file://$filename"
                    );
                }
                when ("xfce") {
                    system( 'xfconf-query', '-c', 'xfce4-desktop', '-p',
                        '/backdrop/screen0/monitor0/image-path', '-s', $filename );
                }
                default {
                    say
                      "Your Desktop Environment ($desk_env) is not supported yet :-(";
                    say "Regardless, your picture is saved at: $filename";
                }
            }    
        }
        default {
            say "Your operating system '$^O' is not supported yet :-(";
            say "Regardless, your picture is saved at: $filename";
        }
    }


    return;
}
