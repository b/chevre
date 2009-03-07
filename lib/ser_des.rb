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

require 'nokogiri'

module SerDes
  def flatten(hdesc)
    hdesc.inject({}) do |memo, kv|
      memo[kv[0]] ||= {}
      memo[kv[0]].merge(flatten_r(kv[0], kv[1]))
    end
  end

  def flatten_r(key, hdesc)  
    if hdesc.is_a?(String)
      return { key => hdesc }
    end

    if hdesc.is_a?(Array)
      ks = (hdesc.map do |m|
        m.is_a?(Hash) ? m.keys.first : nil
      end).compact
      if ks == ks.uniq
        # we can safely hashify the array
        h = { key => (hdesc.inject({}) do |memo, h|
          if h.values.first["_content"].is_a?(String)
            memo[h.keys.first] = h.values.first["_content"]
          else
            memo[h.keys.first] ||= {}
            memo.merge!(flatten_r(h.keys.first, h.values.first))
          end
          memo
        end)}
        return h
      else
        return { key => (hdesc.map do |h|
            flatten_r(h.keys.first, h.values.first)
          end).compact
        }
      end
    end

    if hdesc.is_a?(Hash)
      h = {}
      if hdesc.has_key?("_content")
        if hdesc["_content"].is_a?(String)
          h = { key => hdesc["_content"] }
        else
          h = flatten_r(key, hdesc["_content"])
        end
      end
      if hdesc.has_key?("_attributes")
        if h.is_a?(Hash)
          h[key] ||= {}
          if h[key].is_a?(Array)
            h[key] << hdesc["_attributes"]
          else
            h[key].merge!(hdesc["_attributes"])
          end
        else
          h << hdesc["_attributes"]
        end
      end
      return h
    end
  end

  def parse_xml_desc(xml)
    # consumes the xml_desc blob from libvirt
    # produces an intermediate form composed of ruby hashes and arrays
    # feeds the intermediate form to a class-specific transform to get to
    #  the final, clean form for general use.
    d = Nokogiri::XML((xml.split("\n").each {|line| line.strip}).join)
    transform_from_hash_desc(parse_xml_desc_r(d.root.name, d.root))
  end

  def parse_xml_desc_r(name, xdesc)
    h = {}
    h["_attributes"] = xdesc.attributes.inject({}) {|memo, kv| memo[kv[0].to_s] = kv[1].to_s; memo} if xdesc.attributes.keys.length > 0
    if xdesc.children.length == 0
      h["_content"] = xdesc.content.to_s.strip if xdesc.content.to_s.strip.length > 0
    else
      if (xdesc.children.select {|child| child.name.eql?("text") ? false : true}).length > 0
        h["_content"] = (xdesc.children.map do |child|
          next if child.name.eql?("text")
          parse_xml_desc_r(child.name, child)
        end
        ).compact
      else
        h["_content"] = xdesc.content.to_s.strip if xdesc.content.to_s.strip.length > 0
      end
    end
    { name => h }
  end
end