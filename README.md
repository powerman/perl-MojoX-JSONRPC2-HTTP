[![Build Status](https://travis-ci.org/powerman/perl-MojoX-JSONRPC2-HTTP.svg?branch=master)](https://travis-ci.org/powerman/perl-MojoX-JSONRPC2-HTTP)
[![Coverage Status](https://coveralls.io/repos/powerman/perl-MojoX-JSONRPC2-HTTP/badge.svg?branch=master)](https://coveralls.io/r/powerman/perl-MojoX-JSONRPC2-HTTP?branch=master)

# NAME

MojoX::JSONRPC2::HTTP - Client for JSON RPC 2.0 over HTTP

# VERSION

This document describes MojoX::JSONRPC2::HTTP version v2.0.0

# SYNOPSIS

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

# DESCRIPTION

Provide HTTP transport for JSON RPC 2.0 using Mojo::UserAgent.

Implements this spec: [http://www.simple-is-better.org/json-rpc/transport\_http.html](http://www.simple-is-better.org/json-rpc/transport_http.html).
The "pipelined Requests/Responses" is not supported yet.

# ATTRIBUTES

All these methods return current value when called without params or set
new value and return their object (to allow method chaining) when called
with single param.

## url

RPC endpoint url.

This is only required parameter which must be set before doing RPC calls.

## method

Default is `'POST'`, and only another supported value is `'GET'`.

## type

Default is `'application/json'`.

## headers

Default is empty HASHREF. Either modify it by reference or set it to your
own HASHREF with any extra headers you need to send with RPC call.

## ua

`Mojo::UserAgent` object used for sending HTTP requests - feel free to
setup it or replace with your own object.

# METHODS

## new

    $client = MojoX::JSONRPC2::HTTP->new( %attrs );
    $client = MojoX::JSONRPC2::HTTP->new( \%attrs );

You can set attributes listed above by providing their values when calling
`new()` or later using individual attribute methods.

## call

    ($failed, $result, $error) = $client->call( 'method', @params );
    ($failed, $result, $error) = $client->call_named( 'method', %params );
    $client->call( 'method', @params, \&cb );
    $client->call_named( 'method', %params, \&cb );

Do blocking or non-blocking (when `\&cb` param provided) RPC calls, with
either positional or named params. Blocking calls will return these values
(non-blocking will call `\&cb` with same values as params):

    ($failed, $result, $error)

In case of transport-level errors, when we fail to either send RPC request
or receive correct reply from RPC server the `$failed` will contain error
message, while `$result` and `$error` will be undefined.

In case remote `'method'` or RPC server itself will return error it will
be available in `$error` as HASHREF with keys `{code}`, `{message}` and
optionally `{data}`, while `$failed` and `$result` will be undefined.

Otherwise value returned by remote `'method'` will be in `$result`,
while `$failed` and `$error` will be undefined.

## notify

    $failed = $client->notify( 'method', @params );
    $failed = $client->notify_named( 'method', %params );
    $client->notify( 'method', @params, \&cb );
    $client->notify_named( 'method', %params, \&cb );

Do blocking or non-blocking (when `\&cb` param provided) RPC calls, with
either positional or named params. Blocking calls will return this value
(non-blocking will call `\&cb` with same value as param):

    $failed

It will contain error message in case of transport-level error or will be
undefined if RPC call was executes successfully.

# SEE ALSO

[JSON::RPC2::Client](https://metacpan.org/pod/JSON::RPC2::Client), [Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Plugin::JSONRPC2](https://metacpan.org/pod/Mojolicious::Plugin::JSONRPC2).

# LIMITATIONS

- Batch/Multicall feature

    Not supported because it is not implemented by [JSON::RPC2::Client](https://metacpan.org/pod/JSON::RPC2::Client).

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/powerman/perl-MojoX-JSONRPC2-HTTP/issues](https://github.com/powerman/perl-MojoX-JSONRPC2-HTTP/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

[https://github.com/powerman/perl-MojoX-JSONRPC2-HTTP](https://github.com/powerman/perl-MojoX-JSONRPC2-HTTP)

    git clone https://github.com/powerman/perl-MojoX-JSONRPC2-HTTP.git

## Resources

- MetaCPAN Search

    [https://metacpan.org/search?q=MojoX-JSONRPC2-HTTP](https://metacpan.org/search?q=MojoX-JSONRPC2-HTTP)

- CPAN Ratings

    [http://cpanratings.perl.org/dist/MojoX-JSONRPC2-HTTP](http://cpanratings.perl.org/dist/MojoX-JSONRPC2-HTTP)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/MojoX-JSONRPC2-HTTP](http://annocpan.org/dist/MojoX-JSONRPC2-HTTP)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=MojoX-JSONRPC2-HTTP](http://matrix.cpantesters.org/?dist=MojoX-JSONRPC2-HTTP)

- CPANTS: A CPAN Testing Service (Kwalitee)

    [http://cpants.cpanauthors.org/dist/MojoX-JSONRPC2-HTTP](http://cpants.cpanauthors.org/dist/MojoX-JSONRPC2-HTTP)

# AUTHOR

Alex Efros &lt;powerman@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2014- by Alex Efros &lt;powerman@cpan.org>.

This is free software, licensed under:

    The MIT (X11) License
