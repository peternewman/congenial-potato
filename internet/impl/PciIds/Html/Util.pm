package PciIds::Html::Util;
use strict;
use warnings;
use HTML::Entities;
use base 'Exporter';
use PciIds::Users;
use Apache2::Const qw(:common :http);
use APR::Table;

our @EXPORT = qw(&genHtmlHead &htmlDiv &genHtmlTail &genTableHead &genTableTail &parseArgs &buildExcept &buildArgs &genMenu &genCustomMenu &encode &setAddrPrefix &HTTPRedirect);

sub encode( $ ) {
	return encode_entities( shift, "\"'&<>" );
}

sub genHtmlHead( $$$ ) {
	my( $req, $caption, $metas ) = @_;
	$req->content_type( 'text/html; charset=utf-8' );
	$req->headers_out->add( 'Cache-control' => 'no-cache' );
	print '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'."\n";
	print '<html lang="en"><head><title>'.encode( $caption )."</title>\n";
	print "<link rel='stylesheet' type='text/css' media='screen' href='/static/screen.css'>\n";
	print "<link rel='stylesheet' type='text/css' media='print' href='/static/print.css'>\n";
	print $metas if( defined( $metas ) );
	print "</head><body>\n";
}

sub genHtmlTail() {
	print '</body></html>';
}

sub htmlDiv( $$ ) {
	my( $class, $text ) = @_;
	return '<div class="'.$class.'">'.$text.'</div>';
}

sub item( $$$ ) {
	my( $url, $label, $action ) = @_;
	print "  <li><a href='".$url.$action."'>$label</a>\n";
}

sub genCustomMenu( $$$ ) {
	my( $address, $args, $list ) = @_;
	my $url = '/'.$address->get().buildExcept( 'action', $args ).'?action=';
	print "<div class='menu'>\n<ul>\n";
	foreach( @{$list} ) {
		my( $label, $action ) = @{$_};
		my $prefix = '/mods';
		$prefix = '/read' if( !defined( $action ) or ( $action eq 'list' ) or ( $action eq '' ) );
		item( $prefix.$url, $label, $action );
	}
	print "</ul></div>\n";
}

sub genMenu( $$$ ) {
	my( $address, $args, $auth ) = @_;
	my @list;
	if( defined( $auth->{'authid'} ) ) {
		push @list, [ 'Log out', 'logout' ];
	} else {
		push @list, [ 'Log in', 'login' ];
	}
	push @list, [ 'Add item', 'newitem' ] if( $address->canAddItem() );
	push @list, [ 'Discuss', 'newcomment' ] if( $address->canAddComment() );
	push @list, [ 'Administrate', 'admin' ] if( hasRight( $auth->{'accrights'}, 'validate' ) );
	push @list, [ 'Profile', 'profile' ] if defined $auth->{'authid'};
	push @list, [ 'Notifications', 'notifications' ] if defined $auth->{'authid'};
	genCustomMenu( $address, $args, \@list );
}

sub genTableHead( $$ ) {
	my( $class, $captions ) = @_;
	print '<table class="'.$class.'"><tr>';
	foreach( @{$captions} ) {
		print '<th>'.$_;
	}
	print '</tr>';
}

sub genTableTail() {
	print '</table>';
}

sub parseArgs( $ ) {
	my %result;
	foreach( split /\?/, shift ) {
		next unless( /=/ );
		my( $name, $value ) = /^([^=]+)=(.*)$/;
		$result{$name} = $value;
	}
	return \%result;
}

sub buildArgs( $ ) {
	my( $args ) = @_;
	my $result = '';
	$result .= "?$_=".$args->{$_} foreach( keys %{$args} );
	return $result;
}

sub buildExcept( $$ ) {
	my( $except, $args ) = @_;
	my %backup = %{$args};
	delete $backup{$except};
	return buildArgs( \%backup );
}

sub setAddrPrefix( $$ ) {
	my( $addr, $prefix ) = @_;
	$addr =~ s/\/(mods|read|static)//;
	return "/$prefix$addr";
}

sub HTTPRedirect( $$ ) {
	my( $req, $link ) = @_;
	$req->headers_out->add( 'Location' => $link );
	return HTTP_SEE_OTHER;
}

1;
