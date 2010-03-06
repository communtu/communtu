#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Author: Timo Denissen
E-Mail: timo@communtu.com
About this program: This program is for creating new and editing
                    existing *.gpx files at the computer for using
                    them with the Java application "TrekBuddy".
Version: 0.1A.0
Todo: - Check template.yml for double values *WIP*
      - If double entries exist, ask the user which to use and delete
        the other value(s)
        - Edit the source files accordingly to the changes
        - Give the possibility to change the key name
      - GUI
'''

import yaml

def arbeit():
    mydict = yaml.load(template_yml)
    print mydict
    template_yml.close()
    print 'File closed.'

# Asking which file to work with. Either default or a file chosen by the user.
print 'This program is pre-alpha and not meant for even testing purposes!'
print 'File loss may occur!'
use_file = raw_input('Use "config/locales/template.yml"? y/n ')
if use_file == "y":
    template_yml = open('config/locales/template.yml')
    print template_yml
    arbeit()
elif use_file == "n":
    template_yml = open(raw_input('Which file to use? '))
    print template_yml
    arbeit()
else:
    print "Exiting"
