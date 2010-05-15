#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Author: Timo Denissen
E-Mail: timo@communtu.com
About this program: 
Todo: - Edit the source files accordingly to the changes
      - Give the possibility to change the key name
      - GUI
'''

import yaml
import os

def arbeit():
    '''Working with the file.'''
    mydict = yaml.safe_load(template_yml)
    template_yml.close()
    new_dict = switch_keyvalue(mydict['de'])
    check_dict(new_dict)
    print 'Exit'
    
def check_dict(dict):
    '''Check if there are multiple values for one key.'''
    for key, value in dict.iteritems():
        if len(value) > 1:
            print 'Please solve this conflict:'
            multiple_string = value
            print value, ':', key ,'\n'
            ask_string(multiple_string)
        else:
            pass

def ask_string(string):
    '''Ask user which string to use in templaye.yml'''
    temp_dict = {}
    x = 1
    for item in string:
        temp_dict[x] = item
        print x, item
        x += 1
    ask_number = input('Enter the number of the correct key: ')
    newkey = temp_dict[ask_number]
    string.remove(newkey)
    oldkey_temp = string
    edit_files(oldkey_temp, newkey)
    
def edit_files(oldkey, newkey):
    '''Using "sed" to remove oldkey from source files.'''
    for item in oldkey:
        oldkey = item
        sed = 'find app lib -name "*rb" -exec sed -i \'s/t(:' + oldkey + '\([^:alnum:_]\)/t(:' + newkey + '\1/g\' {} \;'
        print sed
#        os.system(sed)
        edit_template(item)
    print '----------'
    
def edit_template(key):
    '''Editing the template.yml and removing multiple key:value pairs.'''
    template_yml = open('config/locales/template_short.yml')
    template_dict_full = yaml.safe_load(template_yml)
#    print template_dict_full
    template_dict = template_dict_full['de']
    template_yml.close()
#    print template_dict
    template_yml = open('config/locales/template_short.yml', 'w')
    del template_dict[key]
#    print template_dict
    template_yml.write(yaml.dump(template_dict_full, default_flow_style=False))
#    print yaml.dump(template_dict_full, default_flow_style=False)
    template_yml.close()

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
print 'This program is beta.'
print 'THIS IS NOT MEANT FOR PRODUCTIVE USAGE!!! YOU HAVE BEEN WARNED!!!'
print 'Using file "config/locales/template.yml"'
template_yml = open('config/locales/template_short.yml')
arbeit()
