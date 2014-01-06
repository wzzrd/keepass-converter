#!/usr/bin/env ruby

# converter.rb - Convert Revelation XML output to KeepassX input
# Copyright (c) 2008 Maxim Burgerhout
# Author: Maxim Burgerhout <maxim@wzzrd.com>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

# To do:
# - convert Revelation items that have attached keyfiles
# - convert several other Revelation item types 
##  (see the list of generics down below)
# - convert KeepassX output back to Revelation XML
# - warn if Revelation XML is not convertable (items in root)
# - test some more

require "rexml/document"
include REXML

def print_usage
  puts "Usage: converter.rb input_filename output_filename"
  puts "input_filename: your Revelation XML export file."
  puts "output_filename: newly converted XML, ready for KeepassX."
  exit 1
end

if ARGV.length != 2
  print_usage
end

old_filename = ARGV[0]
new_filename = ARGV[1]

old_doc = Document.new File.open(old_filename, "r")
old_root = old_doc.root

new_doc = Document.new("<!DOCTYPE KEEPASSX_DATABASE>
                        <database>
                        </database>")
new_root = new_doc.root
new_file = File.new(new_filename, "w+")

def parse_folder(old_element, new_parent)

  old_element.elements.each { |e|

  if e.name == "entry" and e.attributes["type"] == "folder"
    entry = new_parent.add_element "group"
    icon = entry.add_element "icon"
    icon.text = "1"
    parse_folder(e, entry)
  elsif e.name == "entry" and e.attributes["type"] != "folder"
    entry = new_parent.add_element "entry"
    icon = entry.add_element "icon"
    icon.text = "0"
    parse_folder(e, entry)
  else
    entry = new_parent
  end

  if e.name == "name"
    title = entry.add_element "title"
    title.text = e.text
  end

  if e.name == "updated"
    lastmod_time = e.text.to_i
    lastmod_time = Time.at(lastmod_time)
    lastmod_time = lastmod_time.strftime("%Y-%m-%dT%H:%M:%S")
    lastmod = entry.add_element "lastmod"
    lastaccess = entry.add_element "lastaccess"
    creation = entry.add_element "creation"
    lastmod.text = lastmod_time
    creation.text = lastmod_time
    lastaccess.text = lastmod_time
  end

  if e.name == "field"
    case e.attributes["id"]
      when "generic-username"
        username = entry.add_element "username"
        username.text = e.text
      when "generic-password"
        password = entry.add_element "password"
        password.text = e.text
      when "generic-hostname"
        url = entry.add_element "url"
        url.text = e.text
      when "generic-certificate"
      when "generic-code"
      when "generic-database"
      when "generic-domain"
      when "generic-email"
      when "generic-keyfile"
      when "generic-location"
      when "generic-pin"
      when "generic-port"
      when "generic-url"
    end
  end

  if e.name == "description"
    desc = entry.add_element "comment"
    desc.text = e.text
  end
# 
  }
end

parse_folder(old_root, new_root)

formatter = REXML::Formatters::Default.new( 2 )
formatter.write(new_doc, new_file)
