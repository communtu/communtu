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

def arbeit():
    '''Working with the file.'''
    mydict = yaml.load(template_yml)
    template_yml.close()
    new_dict = switch_keyvalue(mydict['de'])
    check_dict(new_dict)    
    print 'Exit'

def check_dict(dict):
    '''Check if there are multiple values for one key.'''
    for key, value in dict.iteritems():
        if len(value) > 1:
            print 'Found the following duplicate values:'
            print value, ':', key
        else:
            pass
    

def switch_keyvalue(dict):
    '''Switching the key:value pairs in the template.yml file.'''
    new_dict = {}
    for key, value in dict.iteritems():
        if value in new_dict:
            new_dict[value].append(key)
        else:
            new_dict[value] = [key]
    return new_dict
    
'''Choosing the file to work with.'''
print 'This program is beta'
print 'Using file "config/locales/template.yml"'
template_yml = open('config/locales/template.yml')
arbeit()
