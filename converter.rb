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
new_root = new_root.add_element "group"
revgroup = new_root.add_element "title"
revgroup.text = "Revelation Import"
new_file = File.new(new_filename, "w+")

def add_thing(source, target, name, lwrapper="", rwrapper="")
    element = target.elements[name]
    if element == nil
      element = target.add_element name
      element.text = ''
    end
    if source.text.to_s.strip != ''
      element.text = element.text + lwrapper + source.text.to_s + rwrapper
    end
end

def parse_folder(old_element, new_parent)

  old_element.elements.each { |e|

  icons = { "creditcard" => 9, "database" => 43, "door" => 60, "generic" => 13,
            "cryptokey" => 0, "email" => 19, "phone" => 68, 
            "remotedesktop" => 35, "shell" => 30, "vnc" => 35, "website" => 1, 
            "ftp" => 27 }
  icons.default = 2

  if e.name == "entry" and e.attributes["type"] == "folder"
    entry = new_parent.add_element "group"
    icon = entry.add_element "icon"
    icon.text = "48"
    parse_folder(e, entry)
  elsif e.name == "entry" and e.attributes["type"] != "folder"
    entry = new_parent.add_element "entry"
    icon = entry.add_element "icon"
    icon.text = icons[e.attributes["type"]]
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
        add_thing(e, entry, "username")
      when "generic-password"
        add_thing(e, entry, "password")
      when "generic-hostname"
        add_thing(e, entry, "url")
      when "generic-url"
        add_thing(e, entry, "url")
      when "generic-certificate"
        add_thing(e, entry, "comment", "\nCertificate: ", "\n")
      when "generic-code"
        add_thing(e, entry, "password")
      when "generic-database"
        add_thing(e, entry, "comment", "\nDatabase: ", "\n")
      when "generic-domain"
        add_thing(e, entry, "comment", "\nDomain: ", "\n")
      when "generic-email"
        add_thing(e, entry, "username", "<", ">")
      when "generic-keyfile"
        add_thing(e, entry, "comment", "\nKeyfile: ", "\n")
      when "generic-location"
        add_thing(e, entry, "username")
      when "generic-pin"
        add_thing(e, entry, "password")
      when "generic-port"
        add_thing(e, entry, "comment", "\nPort: ", "\n")
      when "creditcard-cardtype"
        add_thing(e, entry, "comment", "\nCardtype: ", "\n")
      when "creditcard-cardnumber"
        add_thing(e, entry, "username")
      when "creditcard-expirydate"
        add_thing(e, entry, "comment", "\nExpirydate: ", "\n")
      when "creditcard-ccv"
        add_thing(e, entry, "comment", "\nCCV: ", "\n")
      when "phone-phonenumber"
        add_thing(e, entry, "username")
    end
  end

  if e.name == "description"
    add_thing(e,entry, "comment", "*", "*")
  end

  if e.name == "notes"
    add_thing(e, entry, "comment", "\n")
  end

  }
end

parse_folder(old_root, new_root)

formatter = REXML::Formatters::Default.new( 2 )
formatter.write(new_doc, new_file)
