package VOIP::MS;

use 5.008009;

our $VERSION = '0.02';

use Moose;
use MooseX::Params::Validate;

use SOAP::Lite;
use Carp qw(croak);
use POSIX qw(strftime);

has 'username' => (is => 'rw', required => 1, isa => 'Str');
has 'password' => (is => 'rw', required => 1, isa => 'Str');

has soap => (
    is => 'ro', 
    default => sub {
        SOAP::Lite
            -> proxy('https://voip.ms/api/v1/server.php')
            -> ns('http://xml.apache.org/xml-soap', "ns2")
            -> ns('urn://voip.ms', "ns1");
    }
);

sub _soapItem($$) {
    my ($key, $value) = @_;
    SOAP::Data->name(item => \SOAP::Data->value(
        SOAP::Data->name(key => $key),
        SOAP::Data->name(value => $value),
    ));
}

sub _soapCall {
    my $self = shift;
    my $method = shift;
    my %params = @_;
    
    my @params;
    while (my ($k,$v) = each ( %params )) {
        push @params, _soapItem($k,$v);
    }
    push @params, _soapItem( api_username => $self->username ),
                  _soapItem( api_password => $self->password );
    
    my $r = $self->soap->$method(
        SOAP::Data->name('param0' => \SOAP::Data->value(@params))->type("ns2:Map")
    );
    if ($r->fault) {
        croak $r->faultstring || "An error occurred calling $method";
    }
    my $res = $r->result;
    if ($res && $res->{status} ne 'success') {
        croak "$method: " . $res->{status};
    }
    return $res;
}

sub getBalance {
    my $self = shift;
    return $self->_soapCall('getBalance')->{balance}->{current_balance};
}

sub getCDR {
    my ( $self, %params ) = validated_hash( \@_,
        date_from => { isa => 'Str',  optional => 0 },
        date_to   => { isa => 'Str',  optional => 0 },
        timezone  => { isa => 'Num',  optional => 1 },
        answered  => { isa => 'Bool', optional => 1, default => 1 },
        noanswer  => { isa => 'Bool', optional => 1, default => 1 },
        busy      => { isa => 'Bool', optional => 1, default => 1 },
        failed    => { isa => 'Bool', optional => 1, default => 1 },
        calltype  => { isa => 'Str',  optional => 1 },
        callbilling => { isa => 'Str', optional => 1 },
        account   => { isa => 'Str',  optional => 1 },
    );
    
    $params{timezone} ||= int(strftime("%z", localtime)/100);
    
    return $self->_soapCall('getCDR', %params )->{cdr};
}

sub getServersInfo {
   my ( $self, %params ) = validated_hash( \@_,
	server_pop => { isa => 'Num',  optional => 1 },
   );

   return $self->_soapCall('getServersInfo', %params)->{servers};
}

sub getCallAccounts {
   my ( $self, %params ) = validated_hash( \@_,
	client => { isa => 'Str',  optional => 1 },
   );

   return $self->_soapCall('getCallAccounts', %params)->{accounts};
}

sub getCallBilling {
   my ( $self, %params ) = validated_hash( \@_,
   );

   return $self->_soapCall('getCallBilling', %params)->{call_billing};
}

sub getCallTypes {
   my ( $self, %params ) = validated_hash( \@_,
	client => { isa => 'Str',  optional => 1 },
   );

   return $self->_soapCall('getCallTypes', %params)->{call_types};
}

sub getRegistrationStatus {
   my ( $self, %params ) = validated_hash( \@_,
	account => { isa => 'Str',  optional => 0 },
   );

   return $self->_soapCall('getRegistrationStatus', %params);
}

sub getSMS {
   my ( $self, %params ) = validated_hash( \@_,
	sms      => { isa => 'Num',  optional => 1 },
	from     => { isa => 'Str',  optional => 1 },
	to       => { isa => 'Str',  optional => 1 },
	type     => { isa => 'Bool', optional => 1 },
	did      => { isa => 'Num',  optional => 1 },
	contact  => { isa => 'Num',  optional => 1 },
	limit    => { isa => 'Num',  optional => 1 },
	timezone => { isa => 'Num',  optional => 1 },
   );

   return $self->_soapCall('getSMS', %params);
}

sub getPackages {
   my ( $self, %params ) = validated_hash( \@_,
	package => { isa => 'Num',  optional => 1 },
   );

   return $self->_soapCall('getPackages', %params);
}

sub getDIDsInfo {
   my ( $self, %params ) = validated_hash( \@_,
	client => { isa => 'Str',  optional => 1 },
	did    => { isa => 'Num',  optional => 1 },
   );

   return $self->_soapCall('getDIDsInfo', %params);
}

sub getDIDCountries {
   my ( $self, %params ) = validated_hash( \@_,
	country_id => { isa => 'Num',  optional => 1 },
	type       => { isa => 'Str',  optional => 1 },
   );

   return $self->_soapCall('getDIDCountries', %params)->{countries};
}

sub getCarriers {
   my ( $self, %params ) = validated_hash( \@_,
	carrier    => { isa => 'Num',  optional => 1 },
   );

   return $self->_soapCall('getCarriers', %params)->{carriers};
}

sub getDIDsCAN {
   my ( $self, %params ) = validated_hash( \@_,
	province   => { isa => 'Num',  optional => 0 },
	ratecenter => { isa => 'Num',  optional => 1 },
   );

   return $self->_soapCall('getDIDsCAN', %params)->{dids};
}

sub getDIDsUSA {
   my ( $self, %params ) = validated_hash( \@_,
	state      => { isa => 'Num',  optional => 0 },
	ratecenter => { isa => 'Num',  optional => 1 },
   );

   return $self->_soapCall('getDIDsUSA', %params)->{dids};
}

sub getDISAs {
   my ( $self, %params ) = validated_hash( \@_,
	disa       => { isa => 'Num',  optional => 1 },
   );

   return $self->_soapCall('getDISAs', %params)->{disa};
}

sub getIVRs {
   my ( $self, %params ) = validated_hash( \@_,
	ivr => { isa => 'Num',  optional => 1 },
   );

   return $self->_soapCall('getIVRs', %params)->{ivrs};
}

sub getForwardings {
   my ( $self, %params ) = validated_hash( \@_,
	forwarding       => { isa => 'Num',  optional => 1 },
   );

   return $self->_soapCall('getForwardings', %params)->{forwardings};
}

sub getInternationalTypes {
   my ( $self, %params ) = validated_hash( \@_,
	type => { isa => 'Str',  optional => 1 },
   );

   return $self->_soapCall('getInternationalTypes', %params)->{types};
}

sub getDIDsInternationalGeographic {
   my ( $self, %params ) = validated_hash( \@_,
	country_id => { isa => 'Num',  optional => 0 },
   );

   return $self->_soapCall('getDIDsInternationalGeographic', %params)->{locations};
}

sub getDIDsInternationalNational {
   my ( $self, %params ) = validated_hash( \@_,
	country_id => { isa => 'Num',  optional => 0 },
   );

   return $self->_soapCall('getDIDsInternationalNational', %params)->{locations};
}

sub getDIDsInternationalTollFree {
   my ( $self, %params ) = validated_hash( \@_,
	country_id => { isa => 'Num',  optional => 0 },
   );

   return $self->_soapCall('getDIDsInternationalTollFree', %params)->{locations};
}

sub sendSMS {
   my ( $self, %params ) = validated_hash( \@_,
	did     => { isa => 'Num',  optional => 0 },
	dst     => { isa => 'Num',  optional => 0 },
	message => { isa => 'Str',  optional => 0 },
   );

   return $self->_soapCall('sendSMS', %params)->{sms};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

VOIP::MS - Perl module to provide access to the voip.ms API

=head1 SYNOPSIS

  use VOIP::MS;
  my $voip = VOIP::MS->new(username => 'user@name.com', password => 'password');
  print $voip->getBalance(),"\n";

=head1 DESCRIPTION

Preliminary version of VOIP::MS module.

=head1 SEE ALSO

L<SOAP::Lite>, L<Moose>, L<https://www.voip.ms/m/apidocs.php>

=head1 AUTHOR

Roy Hooper, E<lt>L<rhooper@toybox.ca><gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Roy Hooper

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
