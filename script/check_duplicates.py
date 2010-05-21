#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Author: Timo Denissen
E-Mail: timo@communtu.com
About this program: 
Todo: - Give the possibility to change the key name
      - GUI
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
#    update_template()
    
def edit_files(oldkey, newkey):
    '''Using "sed" to remove oldkey from source files.'''
    for item in oldkey:
        oldkey = item
        sed = 'find app lib -name "*rb" -exec sed -i \'s/t(:' + oldkey + '\([^:alnum:_]\)/t(:' + newkey + '\\1/g\' {} \;'
        print 'These files will be changed:\n'
        os.system('grep --include=\'*rb\' "' + oldkey + '" ./app -r')
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
#    print yaml.dump_all([template_dict_full], default_flow_style=False, width=300, line_break=False, allow_unicode=True, explicit_start=True)
    yaml.dump_all([template_dict_full], stream=template_yml, default_flow_style=False, width=1024, line_break=False, allow_unicode=True, explicit_start=True)
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
    
def update_template():
    '''Clearing false encodings from template.yml'''
    print 'Updating template.yml'
    replace = {'\\xDC': 'Ü',
               '\\xFC': 'ü',
               '\\xC4': 'Ä',
               '\\xE4': 'ä',
               '\\xD6': 'Ö',
               '\\xF6': 'ö',
               '\\xDF': 'ß'}
    for key, value in replace.iteritems():
        wrong_key = key
        correct_key = value
        sed = "sed -i 's/\\" + wrong_key + "/" + correct_key + "/g' config/locales/template.yml"
        os.system(sed)

'''Choosing the file to work with.'''
print 'Using file "config/locales/template.yml"'
template_yml = open('config/locales/template.yml')
file_processing()
print 'Exit'
