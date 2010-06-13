#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Author: Timo Denissen
E-Mail: timo@communtu.org
About this program: This program is about removing multiple entries from the template.yml file.
Todo: - GUI
'''

import yaml
import os

def file_processing():
    '''Working with the file.'''
    mydict = yaml.safe_load(template_yml)
    template_yml.close()
    new_dict = switch_keyvalue(mydict['de'])
    check_dict(new_dict)
    
def check_dict(dict):
    '''Check if there are multiple values for one key.'''
    for key, value in dict.iteritems():
        if len(value) > 1:
            print 'Please solve this conflict:'
            multiple_string = value
            print value, ':', key ,'\n'
            ask_string(multiple_string, key)
        else:
            pass

def ask_string(string, key):
    '''Ask user which string to use in templaye.yml'''
    temp_dict = {}
    x = 1
    for item in string:
        temp_dict[x] = item
        print x, item
        x += 1
    print '0', 'Enter a new name.'
    ask_number = input('Enter the number of the correct key: ')
    if ask_number == 0:
        newkey = raw_input('Enter a new name: ')
        print key
        add_to_template(newkey, key)
    else:
        newkey = temp_dict[ask_number]
        string.remove(newkey)
    oldkey_temp = string
    edit_files(oldkey_temp, newkey)
    
def add_to_template(user_string, new_value):
    '''Add the new key to the template.yml'''
    template_yml = open('config/locales/template.yml')
    template_dict_full = yaml.safe_load(template_yml)
    template_dict = template_dict_full['de']
    template_yml.close()
    template_yml = open('config/locales/template.yml', 'w')
    template_dict[user_string] = new_value
    yaml.dump_all([template_dict_full], stream=template_yml, default_flow_style=False, width=2048, line_break=False, allow_unicode=True, explicit_start=True)

def edit_files(oldkeys, newkey):
    '''Using "sed" to remove oldkey from source files.'''
    for item in oldkeys:
        sed = 'find app lib -name "*rb" -exec sed -i \'s/t(:' + item + '\([^:alnum:_]\)/t(:' + newkey + '\\1/g\' {} \;'
        print 'These files will be changed:\n'
        os.system('grep --include=\'*rb\' "' + item + '" ./app -r')
        if raw_input('\nIs this ok? y/n ') == 'n':
            break
        else:
            pass
        os.system(sed)
        edit_template(item)
    print '----------'

def edit_template(key):
    '''Editing the template.yml and removing multiple key:value pairs.'''
    template_yml = open('config/locales/template.yml')
    template_dict_full = yaml.safe_load(template_yml)
    template_dict = template_dict_full['de']
    template_yml.close()
    template_yml = open('config/locales/template.yml', 'w')
    del template_dict[key]
    yaml.dump_all([template_dict_full], stream=template_yml, default_flow_style=False, width=2048, line_break=False, allow_unicode=True, explicit_start=True)
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
print 'Using file "config/locales/template.yml"'
template_yml = open('config/locales/template.yml')
file_processing()
print 'Exit'
