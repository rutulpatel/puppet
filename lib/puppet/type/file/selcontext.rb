# Manage SELinux context of files.
#
# This code actually manages three pieces of data in the context.
#
# [root@delenn files]# ls -dZ /
# drwxr-xr-x  root root system_u:object_r:root_t         /
#
# The context of '/' here is 'system_u:object_r:root_t'.  This is
# three seperate fields:
#
# system_u is the user context
# object_r is the role context
# root_t is the type context
#
# All three of these fields are returned in a single string by the
# output of the stat command, but set individually with the chcon
# command.  This allows the user to specify a subset of the three
# values while leaving the others alone.
#
# See http://www.nsa.gov/selinux/ for complete docs on SELinux.

module Puppet
    require 'puppet/util/selinux'

    class SELFileContext < Puppet::Property
        include Puppet::Util::SELinux

        def retrieve
            unless @resource.stat(false)
                return :absent
            end
            context = self.get_selinux_current_context(@resource[:path])
            return parse_selinux_context(name, context)
        end

        def retrieve_default_context(property)
            unless context = self.get_selinux_default_context(@resource[:path])
                return nil
            end
            property_default = self.parse_selinux_context(property, context)
            self.debug "Found #{property} default '#{property_default}' for #{@resource[:path]}"
            return property_default
        end

        def sync
            unless @resource.stat(false)
                stat = @resource.stat(true)
                unless stat
                    return nil
                end
            end

            self.set_selinux_context(@resource[:path], @should, name)
            return :file_changed
        end
    end

    Puppet.type(:file).newproperty(:seluser, :parent => Puppet::SELFileContext) do
        desc "What the SELinux User context of the file should be."

        @event = :file_changed
        defaultto { self.retrieve_default_context(:seluser) }
    end

    Puppet.type(:file).newproperty(:selrole, :parent => Puppet::SELFileContext) do
        desc "What the SELinux Role context of the file should be."

        @event = :file_changed
        defaultto { self.retrieve_default_context(:selrole) }
    end

    Puppet.type(:file).newproperty(:seltype, :parent => Puppet::SELFileContext) do
        desc "What the SELinux Type context of the file should be."

        @event = :file_changed
        defaultto { self.retrieve_default_context(:seltype) }
    end

end

