#!/usr/bin/perl

use strict;
use warnings;

use Net::Syslogd;
use IO::File;

my $syslogd = Net::Syslogd->new(-LocalAddr => '', -LocalPort => '')
  or die "Error creating Syslogd listener: ", Net::Syslogd->error;

sub get_log_data{
	my $in_var = $_[0];
	my (@tmp,$temp, $out_var);
	
	@tmp = split(':',$in_var);
	$temp = pop @tmp;
	@tmp = split /  /, $temp, 2;
	$temp = shift @tmp;
	@tmp = split('/',$temp);
	$out_var = pop @tmp;
	return $out_var;
}

sub log_filter{
	my ($log,$severity,$filter) = @_;
	my ($log_datime, $log_device, $log_type, @out);
	
	if (index($log->severity,$severity) == -1) {
		return
	} else {
		if (index($log->message,$filter) == -1) {
			return
		} else {
			$log_type = 1;
			$log_device = get_log_data($log->message);
			$log_datime = $log->time;
			@out = ($log_datime, $log_device, $log_type);
			return @out;
		}
	}
}

sub get_alert_title_content{
	my $log_type = $_[0];
	my (@tmp, @out);
	open(FH1,"./Data/log_to_alert.txt")or die "Can not open alert converter list (./Data/log_to_alert.txt)";
	while(<FH1>) {
		my $line = $_;
		@tmp = split(',',$line);
		if(index($tmp[0], $log_type) != -1) {
			@out = ($tmp[1],$tmp[2]);
		}
	}
	close(FH1);
	return @out;
}

sub get_alert_reciever{
	my $log_device = $_[0];
	my ($out, @tmp);
	
	open(FH2,"./Data/device_to_comp.txt")or die "Can not open reciever list (./Data/device_to_comp.txt)";
	while(<FH2>) {
		my $line = $_;
		@tmp = split(',', $line);
		if(index($tmp[0], $log_device) != -1) {
			$out = $tmp[1];
		}
	}
	close(FH2);
	return $out;
}

sub log_to_alert{
	my ($log_datime, $log_device, $log_type) = @_;
	
	my ($alert_title, $alert_message) = get_alert_title_content($log_type);
	my $alert_target = get_alert_reciever($log_device);
	my @out = ($log_datime,$alert_target, $alert_title, $alert_message);
	
	return @out;
}


sub main{
	while(1) {
		my $message = $syslogd->get_message();
		
		if (!defined($message)) {
			printf "$0: %s\n", Net::Syslogd->error;
			exit 1;
		} elsif ($message == 0) {
			next;
		}
		if (!defined($message->process_message())) {
			printf "$0: %s\n", Net::Syslogd->error;
		} else {
		
			my $filter = 'does not have a portal'; #exemple
			my ($log_datime, $log_device, $log_type) = log_filter($message,$messsage->severity,$filter);
			my ($log_datime,$alert_target, $alert_title, $alert_message) = log_to_alert($log_datime, $log_device, $log_type);
			printf "datime: $log_datime\ntarget: $alert_target\ntitle: $alert_title\nmessage: $alert_message\n";
			# do something with ($log_datime,$alert_target, $alert_title, $alert_message) ===> send slack messages
		}
	}
}

main();


