#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Author: Timo Denissen
E-Mail: timo@communtu.org
About this program: This program is for removing multiple entries from the template.yml file and manual string editing.
'''

import yaml
import os

def file_processing():
    '''Working with the file.'''
    new_dict = switch_keyvalue(template_dict)
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
        add_to_template(newkey, key)
    else:
        newkey = temp_dict[ask_number]
        string.remove(newkey)
    oldkey_temp = string
    edit_files(oldkey_temp, newkey)
    
def add_to_template(user_string, new_value):
    '''Add the new key to the template.yml'''
    template_yml = open('config/locales/template.yml', 'w')
    template_dict[user_string] = new_value
    safe_file(template_dict_full, template_yml)

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
    template_yml = open('config/locales/template.yml', 'w')
    del template_dict[key]
    safe_file(template_dict_full, template_yml)

def switch_keyvalue(dict):
    '''Switching the key:value pairs in the template.yml file.'''
    new_dict = {}
    for key, value in dict.iteritems():
        if value in new_dict:
            new_dict[value].append(key)
        else:
            new_dict[value] = [key]
    return new_dict
    
def safe_file(dictionary, stream_file):
    '''Saving the file using yaml.dump_all'''
    yaml.dump_all([dictionary], stream=stream_file, default_flow_style=False, width=2048, line_break=False, allow_unicode=True, explicit_start=True)
    stream_file.close()
    
def open_file():
    global template_dict_full
    global template_dict
    template_yml = open('config/locales/template.yml')
    print 'Using file "config/locales/template.yml"'
    template_dict_full = yaml.safe_load(template_yml)
    template_dict = template_dict_full['de']
    template_yml.close()
    
def edit_strings():
    '''Manual editing of strings'''
    search = raw_input('Enter the search string: ')
    print '\nSearching for string "' + search +'".\n'
    cache = {}
    cache_value = {}
    count = 0
    for key, value in template_dict.iteritems():
        if search in key:
            count += 1
            cache[count] = [key]
            cache_value[count] = [value]
            print count, key + ':', value
    print '\nFound string', '"' + search + '"', count, 'times.\n'
    ask_number = input('Which string do you want to edit? ')
    oldkey = cache[ask_number]
    value_newkey = str(cache_value[ask_number])[2:-2]
    newkey = raw_input ('Enter the new key: ')
    print oldkey, 'will be replaced with "' + newkey + '".'
    edit_files(oldkey, newkey)
    template_yml = open('config/locales/template.yml', 'w')
    template_dict[newkey] = str([value_newkey])[2:-2]
    safe_file(template_dict_full, template_yml)
    if raw_input('Do you want to edit more strings? y/n ') == 'y':
        edit_strings()
    else:
        print 'Exit'
    
'''Asking the user what to do'''
open_file()
print '\nWhat do you want to do?\n1. Check for multiple entries\n2. Edit strings\n0. Exit\n'
menu = raw_input('What do you want to do? ')
if menu == '1':
    file_processing()
elif menu == '2':
    edit_strings()
else:
    print 'Exit'
