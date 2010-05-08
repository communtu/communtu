#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Author: Timo Denissen
E-Mail: timo@communtu.com
About this program: 
Todo: - If double entries exist, ask the user which to use and delete
        the other value(s)
        - Edit the source files accordingly to the changes
        - Give the possibility to change the key name
      - GUI
'''

import yaml

#Working with the file.
def arbeit():
    mydict = yaml.load(template_yml)
#    print mydict
#    print type(mydict)
    template_yml.close()
    new_dict = switch_keyvalue(mydict['de'])
#    print new_dict
    check_dict(new_dict)    
    print 'Exit'

# Check if there are multiple values for one key.
def check_dict(dict):
    for key, value in dict.iteritems():
        if len(value) > 1:
            print 'Found the following duplicate values:'
            print value, ':', key
        else:
            pass
    
# Switching the key:value pairs in the template.yml file.
def switch_keyvalue(dict):
    new_dict = {}
    for key, value in dict.iteritems():
        if value in new_dict:
            new_dict[value].append(key)
        else:
            new_dict[value] = [key]
    return new_dict
    
# Asking which file to work with. Either default or a file chosen by the user.
print 'This program is beta'
use_file = raw_input('Use "config/locales/template.yml"? y/n ')
if use_file == "y":
    template_yml = open('config/locales/template.yml')
#    print template_yml
    arbeit()
elif use_file == "n":
    template_yml = open(raw_input('Which file to use? '))
#    print template_yml
    arbeit()
else:
    print "Exiting"
