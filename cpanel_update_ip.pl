#!/usr/bin/perl
# -------------------------------------------------------------------------------
# cpanel_update_ip.pl
# More information please have a look at README.md

#--- Required -------------------------------------------------------------------
use strict;
use LWP::UserAgent;
use MIME::Base64;
use XML::Simple;

#--- Configuration --------------------------------------------------------------
my $cpanel = "";    # URL for cPanel
my $hostname = "";  # URL for host
my $domain = "";    # URL for domain/subdomain to update
my $user = "";      # cPanel username
my $pass = "";      # cPanel password

#--- Authentication -------------------------------------------------------------
my $auth = "Basic " . MIME::Base64::encode( $user . ":" . $pass );
my $ua = LWP::UserAgent->new(ssl_opts => {verify_hostname => 0});

# --- Get domain XML ------------------------------------------------------------
sub getDomainHash {
    my $xml = new XML::Simple;
    my $request = HTTP::Request->new(GET => "https://$cpanel:2083/xml-api/cpanel?cpanel_xmlapi_module=ZoneEdit&cpanel_xmlapi_func=fetchzone&domain=$hostname");
    $request->header(Authorization => $auth);
    my $response = $ua->request($request);
    if ($response->is_success) {
        my $zone = $xml->XMLin($response->content);
        if ($zone->{'data'}->{'status'} eq "1") {
            my $count = @{$zone->{'data'}->{'record'}};
            my $paramdomain = $domain.".";
            for (my $item=0; $item<=$count; $item++) {
                my $name = $zone->{'data'}->{'record'}[$item]->{'name'};
                my $type = $zone->{'data'}->{'record'}[$item]->{'type'};
                if (($name eq $paramdomain) && ($type eq "A")) {
                    return $zone->{'data'}->{'record'}[$item];
                }
            }
        }
    }
    return 0;
}

# --- Get line number -----------------------------------------------------------
sub getLineNumberA {
    return $_[0]->{'line'};
}

# --- Get old IP ----------------------------------------------------------------
sub getOldIp {
    return $_[0]->{'address'};
}

# --- Get server Internet IP ----------------------------------------------------
sub getNewIp {
    my $request = HTTP::Request->new(GET => "http://myip.dnsdynamic.com");
    my $response = $ua->request($request);
    if ($response->is_success) {
        return $response->content;
    } else {
        return 0;
    }
}

# --- Change the IP address -----------------------------------------------------
sub setIp {
    my $linenumber = $_[0];
    my $newip = $_[1];
    my $paramdomain = $domain.".";

    my $xml = new XML::Simple;
    my $request = HTTP::Request->new(GET => "https://$cpanel:2083/xml-api/cpanel?cpanel_xmlapi_module=ZoneEdit&cpanel_xmlapi_func=edit_zone_record&domain=$paramdomain&line=$linenumber&address=$newip");
    $request->header(Authorization => $auth);
    my $response = $ua->request($request);
    my $reply = $xml->XMLin($response->content);
    print $reply->{'data'}->{'statusmsg'}."\n".$response->content."\n";
    if ($reply->{'data'}->{'status'} eq "1") {
        return 1;
    }
    return 0;
}

# --- Init ----------------------------------------------------------------------
sub init {
    my $domain_hash = getDomainHash();
    if (!$domain_hash ) {
        die("Error");
    } else {
        my $old_ip = getOldIp($domain_hash);
        my $new_ip = getNewIp();

        if ($old_ip ne $new_ip) {
            setIp(getLineNumberA($domain_hash), $new_ip);
        }
    }
}

# --- Main ----------------------------------------------------------------------
init();

