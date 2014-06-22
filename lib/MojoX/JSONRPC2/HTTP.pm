package MojoX::JSONRPC2::HTTP;

use Mojo::Base -base;
use Carp;

use version; our $VERSION = qv('1.0.0');    # REMINDER: update Changes

# REMINDER: update dependencies in Build.PL
use Mojo::UserAgent;
use JSON::RPC2::Client 0.2.0;   ## no critic (ProhibitVersionStrings)
use JSON::XS;
use Scalar::Util qw(weaken);

use constant REQUEST_TIMEOUT    => 30;
use constant HTTP_200           => 200;


has url     => sub { croak '->url() not defined' };
has method  => 'POST';
has type    => 'application/json';
has headers => sub { {} };
has ua      => sub {
    Mojo::UserAgent->new
        ->inactivity_timeout(0)
        ->request_timeout(REQUEST_TIMEOUT)
};
has _client => sub { JSON::RPC2::Client->new };

sub call            { return shift->_request('call',         @_) }
sub call_named      { return shift->_request('call_named',   @_) }
sub notify          { return shift->_request('notify',       @_) }
sub notify_named    { return shift->_request('notify_named', @_) }

sub _request {
    my ($self, $func, $method, @params) = @_;
    # work either in blocking mode or non-blocking (if has \&cb in last param)
    my $cb = @params && ref $params[-1] eq 'CODE' ? pop @params : undef;

    # if $func is notify/notify_named then $call will be undef
    my ($json_request, $call) = $self->_client->$func($method, @params);

    my $tx; # will be set when in blocking mode
    weaken(my $this = $self);
    if ('GET' eq uc $self->method) {
        my $json = decode_json($json_request);
        if (exists $json->{params}) {
            $json->{params} = encode_json($json->{params});
        }
        $tx = $self->ua->get(
            $self->url,
            {
                'Content-Type'  => $self->type,
                'Accept'        => $self->type,
                %{ $self->headers },
            },
            form => $json,
            ($cb ? sub {$this && $this->_response($cb, $call, @_)} : ()),
        );
    }
    else {
        $tx = $self->ua->post(
            $self->url,
            {
                'Content-Type'  => $self->type,
                'Accept'        => $self->type,
                %{ $self->headers },
            },
            $json_request,
            ($cb ? sub {$this && $this->_response($cb, $call, @_)} : ()),
        );
    }
    return ($cb ? () : $self->_response($cb, $call, undef, $tx));
}

sub _response {
    my ($self, $cb, $call, undef, $tx) = @_;
    my $is_notify = !defined $call;

    my ($failed, $result, $error);
    my $res = $tx->res;
    # transport error (we don't have HTTP reply)
    if ($res->error && !$res->error->{code}) {
        $failed = $res->error->{message};
    }
    # use HTTP code as error message instead of 'Parse error' for:
    # - strange HTTP reply code or non-empty content (notify)
    elsif ($is_notify  && !($res->is_status_class(HTTP_200) && $res->body =~ /\A\s*\z/ms)) {
        $failed = sprintf '%d %s', $res->code, $res->message;
    }
    # - strange HTTP reply code or non-json content (call)
    elsif (!$is_notify && !($res->is_status_class(HTTP_200) && $res->body =~ /\A\s*[{\[]/ms)) {
        $failed = sprintf '%d %s', $res->code, $res->message;
    }
    elsif (!$is_notify) {
        ($failed, $result, $error) = $self->_client->response($res->body);
    }

    if ($failed && $call) {
        $self->_client->cancel($call);
    }

    if ($cb) {
        return $is_notify ? $cb->($failed) : $cb->($failed, $result, $error);
    } else {
        return $is_notify ?       $failed  :      ($failed, $result, $error);
    }
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

MojoX::JSONRPC2::HTTP - Client for JSON RPC 2.0 over HTTP


=head1 SYNOPSIS

    use MojoX::JSONRPC2::HTTP;

    $client = MojoX::JSONRPC2::HTTP->new;

    # setup
    $client
        ->url('http://example.com/endpoint')
        ->method('GET')
        ->type('application/json-rpc')
        ->headers({'X-Answer'=>42,…})
        ;
    # get Mojo::UserAgent to setup it (timeouts, etc.)
    $ua = $client->ua;

    # blocking notifications and calls
    ($failed, $result, $error) = $client->call('method', @params);
    ($failed, $result, $error) = $client->call_named('method', %params);
    $failed = $client->notify('method', @params);
    $failed = $client->notify_named('method', %params);

    # non-blocking calls
    $client->call('method', @params, \&cb);
    $client->call_named('method', %params, \&cb);
    sub cb {
        my ($failed, $result, $error) = @_;
    }

    # non-blocking notifications
    $client->notify('method', @params, \&cb_failed);
    $client->notify_named('method', %params, \&cb_failed);
    sub cb_failed {
        my ($failed) = @_;
    }


=head1 DESCRIPTION

Provide HTTP transport for JSON RPC 2.0 using Mojo::UserAgent.

Implements this spec: L<http://www.simple-is-better.org/json-rpc/transport_http.html>.
The "pipelined Requests/Responses" is not supported yet.


=head1 ATTRIBUTES

All these methods return current value when called without params or set
new value and return their object (to allow method chaining) when called
with single param.

=over

=item url

RPC endpoint url.

This is only required parameter which must be set before doing RPC calls.

=item method

Default is C<'POST'>, and only another supported value is C<'GET'>.

=item type

Default is C<'application/json'>.

=item headers

Default is empty HASHREF. Either modify it by reference or set it to your
own HASHREF with any extra headers you need to send with RPC call.

=item ua

C<Mojo::UserAgent> object used for sending HTTP requests - feel free to
setup it or replace with your own object.

=back


=head1 METHODS

=over

=item new( %attrs )

=item new( \%attrs )

You can set attributes listed above by providing their values when calling
C<new()> or later using individual attribute methods.

=item call( 'method', @params )

=item call( 'method', @params, \&cb )

=item call_named( 'method', %params )

=item call_named( 'method', %params, \&cb )

Do blocking or non-blocking (when C<\&cb> param provided) RPC calls, with
either positional or named params. Blocking calls will return these values
(non-blocking will call C<\&cb> with same values as params):

    ($failed, $result, $error)

In case of transport-level errors, when we fail to either send RPC request
or receive correct reply from RPC server the C<$failed> will contain error
message, while C<$result> and C<$error> will be undefined.

In case remote C<'method'> or RPC server itself will return error it will
be available in C<$error> as HASHREF with keys C<{code}>, C<{message}> and
optionally C<{data}>, while C<$failed> and C<$result> will be undefined.

Otherwise value returned by remote C<'method'> will be in C<$result>,
while C<$failed> and C<$error> will be undefined.

=item notify( 'method', @params )

=item notify( 'method', @params, \&cb )

=item notify_named( 'method', %params )

=item notify_named( 'method', %params, \&cb )

Do blocking or non-blocking (when C<\&cb> param provided) RPC calls, with
either positional or named params. Blocking calls will return this value
(non-blocking will call C<\&cb> with same value as param):

    $failed

It will contain error message in case of transport-level error or will be
undefined if RPC call was executes successfully.

=back


=head1 SEE ALSO

L<JSON::RPC2::Client>, L<Mojolicious>, L<Mojolicious::Plugin::JSONRPC2>.


=head1 BUGS AND LIMITATIONS

=over

=item Batch/Multicall feature

Not supported because it is not implemented by L<JSON::RPC2::Client>.

=back

No bugs have been reported.


=head1 SUPPORT

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-JSONRPC2-HTTP>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

You can also look for information at:

=over

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-JSONRPC2-HTTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-JSONRPC2-HTTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-JSONRPC2-HTTP>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-JSONRPC2-HTTP/>

=back


=head1 AUTHOR

Alex Efros  C<< <powerman@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Alex Efros <powerman@cpan.org>.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

