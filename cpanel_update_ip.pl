#!/usr/bin/perl
# -------------------------------------------------------------------------------
# cpanel_update_ip.pl
# origin author: hwa107 <https://github.com/hwa107>
# contributing author: David Regimbal <regimbal.me>
# More information please have a look at README.md

#--- Required -------------------------------------------------------------------
use strict;
use LWP::UserAgent;
use MIME::Base64;
use XML::Simple;
use File::Slurp;

#--- Configuration -- Do not edit ----------------------------------------------

my $accounts_file = "config.cPanelDDNS.txt"; # path to file (rel to pl file)
my $cpanel;        # URL for cPanel
my $subdomain;     # subdomain name
my $domain;        # example.com
my $user;          # cPanel username
my $pass;          # cPanel password

#--- Do not edit the below variables --------------------------------------------
my $auth;
my $ua;

#--- Get Accounts on file -------------------------------------------------------
sub getAccounts {
  open (my $fh, "<", $accounts_file);
  my @file_array;
  while (my $line = <$fh>) {
      chomp $line;
      my @line_array = split(/\s+/, $line);
      push (@file_array, \@line_array);
  }
  return @file_array;
}

#--- Authentication -------------------------------------------------------------
sub setAuthentication()
{
  $auth = "Basic " . MIME::Base64::encode( $user . ":" . $pass );
  $ua = LWP::UserAgent->new(ssl_opts => {verify_hostname => 0});  
}

sub getDomainHash {
  my $xml = new XML::Simple;
  my $request = HTTP::Request->new(GET => "https://$cpanel:2083/xml-api/cpanel?cpanel_xmlapi_module=ZoneEdit&cpanel_xmlapi_func=fetchzone&domain=$domain");
  $request->header(Authorization => $auth);
  my $response = $ua->request($request);
  if ($response->is_success) {
      my $zone = $xml->XMLin($response->content);
      if ($zone->{'data'}->{'status'} eq "1") {
          my $count = @{$zone->{'data'}->{'record'}};
          my $paramdomain = $subdomain.".".$domain.".";
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
    my $xml = new XML::Simple;
    my $request = HTTP::Request->new(GET => "https://$cpanel:2083/xml-api/cpanel?cpanel_xmlapi_user=regimbal&cpanel_xmlapi_module=ZoneEdit&cpanel_xmlapi_func=edit_zone_record&domain=$domain&name=$subdomain&line=$linenumber&address=$newip");
    
    $request->header(Authorization => $auth);
    my $response = $ua->request($request);
    my $reply = $xml->XMLin($response->content);
    if ($reply->{'data'}->{'status'} eq "1") {
        print STDOUT "Update success!";
        return 1;
    }
    else
    {
      print STDOUT $reply->{'data'}->{'statusmsg'};
    }
    return 0;
}

# --- Init ----------------------------------------------------------------------
sub init {
  
  my @accounts = getAccounts();
  
  foreach my $i ( 0 .. $#accounts )
  {
    #--- Configuration --------------------------------------------------------------
    $cpanel = $accounts[$i][0];        # URL for cPanel
    $subdomain = $accounts[$i][1];     # subdomain name
    $domain = $accounts[$i][2];        # example.com
    $user = $accounts[$i][3];          # cPanel username
    $pass = $accounts[$i][4];          # cPanel password
    
    print STDOUT "Starting check for $domain \n";
    
    setAuthentication();
    
    my $domain_hash = getDomainHash();
  
    if (!$domain_hash ) {
        print STDERR "Could not make a connection to host\n";
    } else {
        my $old_ip = getOldIp($domain_hash);
        my $new_ip = getNewIp();
    
        if ($old_ip ne $new_ip) {
            setIp(getLineNumberA($domain_hash), $new_ip);
        }
        else
        {
          print STDOUT "Your IP has not changed since last checked\n";
        }
    }
  }

}

# --- Main ----------------------------------------------------------------------
init();