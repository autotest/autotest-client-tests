#!/usr/bin/perl -w
use strict;
use XML::RegExp;
use XML::Simple;
use Data::Dumper;

my $booklist = XMLin('test.xml');
foreach my $book (@{$booklist->{book}}) {
	if ($book->{type} eq 'technical') {
	if ($book->{type} =~ /^$XML::RegExp::Name$/){
		print "ok. \n"      }
	else {
		print "not ok \n"}
	if ($book->{isbn} =~ /^$XML::RegExp::NmToken$/){
		print "ok. \n"       }
	else {
		print "not ok 123. \n" }
	if($book->{quality} =~ /^$XML::RegExp::Letter$/){
		print "ok. \n"       }
	else {
		print "not ok. \n" }
	
	if($book->{isbn} =~ /^$XML::RegExp::Digit*$/){
		print "ok. \n"       }
	else {
		print "not ok. \n" }
	if($book->{subject} =~ /^$XML::RegExp::NameChar*$/){
		print "ok. \n"       }
	else {
		print "not ok. \n" }
	if("&#1;" =~ /^$XML::RegExp::CharRef$/){
                print "ok. \n"       }
        else {
                print "not ok. \n" }

	if ("〇" =~ /^$XML::RegExp::Ideographic$/){
		print "ok. \n"      }
	else {
		print "not ok. \n"}
	if ("''" =~ /^$XML::RegExp::AttValue$/){
		print "ok. \n"      }
	else {
		print "not ok. \n"}
	if( "&amp;" =~ /^$XML::RegExp::EntityRef$/){
		print "ok. \n"       }
	else {
		print "not ok. \n" }
	if ("Ì" =~ /^$XML::RegExp::BaseChar$/){
		print "ok. \n"      }
	else {
		print "not ok. \n"}
	if ("·" =~ /^$XML::RegExp::Extender$/){
		print "ok. \n"      }
	else {
		print "not ok. \n"}
	if ("̂" =~ /^$XML::RegExp::CombiningChar$/){
		print "ok. \n"      }
	else {
		print "not ok. \n"}
	if ("ໆ" =~ /^$XML::RegExp::NameChar$/){
		print "ok. \n"      }
	else {
		print "not ok. \n"}
	if ("_" =~ /^$XML::RegExp::NameChar$/){
		print "ok. \n"      }
	else {
		print "not ok. \n"}

	if("&gt;" =~ /^$XML::RegExp::Reference$/){
                print "ok. \n"       }
        else {
                print "not ok. \n" }
	if("-_1·" =~ /^$XML::RegExp::NCNameChar*$/){
                print "ok. \n"       }
        else {
                print "not ok. \n" }
	if("_test_" =~ /^$XML::RegExp::NCName$/){
                print "ok. \n"       }
        else {
                print "not ok. \n" }



}

}




