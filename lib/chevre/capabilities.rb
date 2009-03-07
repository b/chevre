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
  class Capabilities
    include SerDes
    
    attr_reader :desc
    
    def initialize(xml)
      @desc = parse_xml_desc(xml)["capabilities"]
    end
    
    def transform_from_hash_desc(hdesc)
      # consumes the intermediate form produced by parse_xml_desc
      # produces a clean representation for general use
      flatten hdesc
    end
    
    def default
      {
        'arch' => default_guest["arch"].last["name"],
        'domain' => domain_type,
        'os' => os_type,
        'features' => features
      }      
    end

    def features
      default_guest["features"].keys
    end
    
    def default_guest
      if desc.is_a?(Array)
        desc.each do |d|
          if d.keys.first.eql?("guest")
            return d.values.first if d.values.first["arch"]["name"].eql?(host_arch)
          end
        end
      else
        desc["guest"]
      end
    end
    
    def host_arch
      desc["host"]["cpu"]["arch"]
    end
    
    def os_type
      default_guest["os_type"]
    end
    
    def domain_type
      if default_guest["arch"].is_a?(Array)
        default_guest["arch"].each do |a|
          return a["domain"]["type"] if a.keys.first.eql?("domain")
        end
      else
        default_guest["arch"]["domain"]["type"]
      end
    end
            
  end
end
