#!/usr/bin/env python
# -*- coding: utf-8 -*-
from os import listdir

#
def generate_paketlist():
    """
    Erstellt aus den einzelnen User-Dateien zwei nach User
    sortierten Paketlist-Dateien. Eine mit den Daten von
    debfooster und eine mit allen Paketen
    """
    debfooster = open("debfooster","w")
    all = open("all","w")
    for pakete in [file("pakete/" + f) for f in listdir("pakete")]:
        debfooster.write(pakete.readline())
        all.write(pakete.readline())
    debfooster.close()
    all.close()

def loaduserdata(path="debfooster", method="simple"):
    """
    Läd eine durch generate_paketlist() erstellte Datei.
    
    path: Pfad zur Datei, in der Regel debfooster oder all
    method: Die verwendete Methode [simple|complex]
    
    Gibt ein User bezogenes Dict aller Pakete der Datei zurück.
    """
    if method == "simple":
        return loaduserdata_simple(path=path)
    if method == "complex":
        return loaduser_complex(path=path)
    return None

def loaduserdata_simple(path="debfooster"):
    """
    Läd die Userdaten in ein dict welches nur die Information enthält ob
    ein Paket installiert ist
    """
    users = {}
    for line in file(path):
        column = line.strip().split(',')
        users[column[0]] = []
        for package in column[1:]:
            users[column[0]].append(package)
    return users
    
def loaduserdata_complex(path="debfooster"):
    """
    Läd eine durch generate_paketlist() erstellte Datei.
    
    path: Pfad zur Datei, in der Regel debfooster oder all
    
    Gibt ein User bezogenes Dict aller Pakete der Datei zurück.
    """
    #ließt die Datei in ein nach User sortiertes dict ein
    users = {}
    for line in file(path):
        column = line.strip().split(',')
        users[column[0]] = {}
        for package in column[1:]:
            users[column[0]][package] = 1.0
    
    # Erstellt eine Liste aller Pakete
    #packages=[]
    #for user in users:
    #    for package in users[user]:
    #        if package not in packages:
    #            packages.append(package)
    
    # Fügt bei den Usern nicht installierte Pakete zum jeweiligen
    # dict mit einer Bewertung von 0.0 hinzu
    #for user in users:
    #    for package in packages:
    #        if package not in users[user]:
    #            users[user][package] = 0.0
                
    return users

def loaduser(pakages, line=None, method="simple"):
    """
    Ließt die Daten eines Users ein.
    
    packages: ein string welcher die Pakete durch Komma getrennt enthält,
              oder ein file Objekt, welches die Daten in der Zeile line 
              enthält.
              
    line:     ist pakages ein file Objekt, ist dies die Zeile welche Daten enthält
              ansonsten wird die erste Zeile genommen.
              
    method:   Die Angewendete Methode, simple oder complex
    
    Gibt den User als dict zurück
    """
    if method == "simple":
        return loaduser_simple(pakages, line)
    if method == "complex":
        return loaduser_complex(pakages, line)
    return None

def loaduser_simple(pakages, line=None):
    """
    Läd die Userdaten in ein dict welches nur die Information enthält ob
    ein Paket installiert ist
    """
    user = []
    try:
        if line:
            pakageslist = pakages.readlines()[line].split(',')[1:]
        else:
            pakageslist = pakages.readline().split(',')[1:]
    except AttributeError:
        pakageslist = pakages.split(',')
    
    for paket in pakageslist:
        user.append(paket.strip())
    return user
    
def loaduser_complex(pakages, line=None):
    """
    Ließt die Daten eines Users ein dict welches für jedes Paket eine Wertung
    von 1.0 festsetzt.
    """
    user = {}
    try:
        if line:
            pakageslist = pakages.readlines()[line].split(',')[1:]
        else:
            pakageslist = pakages.readline().split(',')[1:]
    except AttributeError:
        pakageslist = pakages.split(',')
        
    for paket in pakageslist:
        user[paket.strip()] = 1.0
    return user

def main():
    
    return 0

if __name__ == '__main__':
    main()
