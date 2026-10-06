#!/usr/bin/env perl
# Простой статический сервер для локального просмотра: perl tools/serve.pl [порт]
use strict; use warnings;
use HTTP::Daemon; use HTTP::Status; use File::Basename; use Cwd qw(abs_path);
my $root = dirname(dirname(abs_path($0)));
my $port = $ARGV[0] || 8585;
my %mime = (html=>'text/html; charset=utf-8', css=>'text/css', js=>'application/javascript', json=>'application/json',
            jpg=>'image/jpeg', jpeg=>'image/jpeg', png=>'image/png', webp=>'image/webp', ico=>'image/x-icon', svg=>'image/svg+xml', txt=>'text/plain; charset=utf-8');
my $d = HTTP::Daemon->new(LocalAddr => '127.0.0.1', LocalPort => $port, ReuseAddr => 1, Listen => 16) or die "Не удалось открыть порт $port: $!";
$| = 1; print "Сайт: http://127.0.0.1:$port/\n";
while (my $c = $d->accept) {
  while (my $r = $c->get_request) {
    my $path = $r->uri->path; $path =~ s/\?.*//; $path = '/index.html' if $path eq '/';
    $path =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
    my $file = "$root$path";
    if ($path =~ /\.\./ || !-f $file) { $c->send_error(RC_NOT_FOUND); next }
    my ($ext) = $file =~ /\.(\w+)$/; my $type = $mime{lc($ext // '')} || 'application/octet-stream';
    # у части картинок с расширением .jpg внутри WebP — браузер разберётся по содержимому
    $c->send_file_response($file) if 0;
    open my $f, '<:raw', $file or do { $c->send_error(RC_INTERNAL_SERVER_ERROR); next };
    local $/; my $body = <$f>; close $f;
    my $res = HTTP::Response->new(RC_OK); $res->header('Content-Type' => $type, 'Content-Length' => length $body, 'Cache-Control' => 'no-cache');
    $res->content($body); $c->send_response($res);
  }
  $c->close; undef $c;
}
