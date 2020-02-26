#
# Copyright 2016 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Written by John Wu (jwu@web.com)
# 2018-06-13

package hardware::server::cisco::ucce::mode::calls;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Data::Dumper;

my %indexes = (
    CallsPerSec => '2.1.1',
    CallsInProgress => '4.1.1',
    CallsInQueue => '8.1.1',
);
my $oid_cccaRouterCalls = '.1.3.6.1.4.1.9.9.473.1.3.1.1';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "warning:s"         => { name => 'warning' },
            "critical:s"        => { name => 'critical' },
        });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $result = $self->{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cccaRouterCalls },
        ],
        nothing_quit => 1,
    );
    #print Data::Dumper->Dump([\$result],[qw(*result)]);

    foreach my $key (keys %indexes) {
	my $index = $indexes{$key};
	my $val = $result->{$oid_cccaRouterCalls}->{$oid_cccaRouterCalls . '.' . $index};
        if ( $key eq 'CallsPerSec' ) {
            my $exit = $self->{perfdata}->threshold_check(value => $val, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("%s: %d", $key, $val),
            );
            $self->{output}->perfdata_add(
                label => $key,
                value => $val,
                warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
            );
        } else {
            $self->{output}->output_add(
                short_msg => sprintf("%s: %d", $key, $val),
            );
        }
    }
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Number of Calls

=over 8

=item B<--warning>

Threshold warning for calls per second.

=item B<--critical>

Threshold critical for calls per second.

=back

=cut
