#
# Author:: Benjamin Black (<bb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# License:: Apache License, Version 2.0
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

module Chevre   
  class Hypervisor
    class << self
      attr_reader :cores, :cpus, :memory, :mhz,
                  :model, :nodes, :sockets, :threads,
                  :capabilities
                        
      def open(uri, options = {})
        options = { "read_only" => true }.merge(options)
        if options["read_only"]
          @connection = Libvirt::open_read_only(uri)
        else
          @connection = Libvirt::open(uri)
        end
        @capabilities = Capabilities.new(@connection.capabilities)
        @_node_info = @connection.node_get_info
        %w{ cores cpus memory mhz model nodes sockets threads }.each do |a|
          instance_variable_set("@#{a}", @_node_info.send(a))
        end
      end

      def close
        @connection.close
      end

    end
  end
end
