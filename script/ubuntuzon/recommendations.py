#!/usr/bin/env python
# -*- coding: utf-8 -*-


from math import sqrt


def sim_simple(prefs, paket1, paket2):
    """
    Vergleicht zwei Pakete anhand der User, welche die Pakete installiert haben
    Gibt die Anzahl der User zurück, welche sowohl das eine als auch das andere
    Paket installiert haben.
    """
    count = 0
    for user in prefs[paket1]:
        if user in prefs[paket2]:
            count += 1
    return count


# Returns the best matches for person from the prefs dictionary. 
# Number of results and similarity function are optional params.
def topMatches(prefs,person,n=5,similarity=sim_simple):
    """
    Gibt die n ähnlichesten Pakete zu einem Paket zurück
    """
    scores=[(similarity(prefs,person,other),other) 
                  for other in prefs if other!=person]
    scores.sort()
    scores.reverse()
    return scores[0:n]


def transformPrefs(prefs):
    """
    Erzeugt aus einer nach Usern sortierten Tabelle eine nach Paketen
    sortierte Tabelle
    """
    result = {}
    for person in prefs:
        for item in prefs[person]:
            result.setdefault(item,[])
            # Flip item and person
            result[item].append(person) # = prefs[person][item]

    return result


def calculateSimilarItems(prefs,n=10,similarity=sim_simple):
    """
    Erzeugt einen Datenbestand, dass für jedes Paket n ähnlichsten Pakete
    beinhaltet
    """
    result = {}
    # Invert the preference matrix to be item-centric
    itemPrefs = transformPrefs(prefs)
    c = 0
    for item in itemPrefs:
        # Status updates for large datasets
        c += 1
        if c%100 == 0:
            print "%d / %d" % (c,len(itemPrefs))
        # Find the most similar items to this one
        scores = topMatches(itemPrefs,item,n=n,similarity=similarity)
        result[item]=scores
    return result

def getRecommendedItems(userRatings,itemMatch):
    """
    Gibt zu einem User eine Liste mit empfohlenen Paketen zurück
    
    userRatings: Eine Liste mit den vom User installierte Paketnamen
    itemMatch: ein durch calculateSimilarItems() erstellter Datenbestand
    """
    scores = {}
    #totalSim = {}

    # Alle Pakete des Users durchgehen
    # paket: Name des paketees
    for paket in userRatings:
        
        try: # Pakete, die nicht in der Datenbank sind, nicht ueberpruefen
            # Alle pakete, die in der DB als ähnlich aufgefürt werden durchgehen.
            # simpaket: Name des ähnlichen Paketes
            # similarity: Wertung wie ähnlich es ist
            for (similarity, simpaket) in itemMatch[paket]:
              
                # Bereits installieret Pakete überspringen
                if simpaket in userRatings:
                    continue
                
                # Weighted sum of rating times similarity
                scores.setdefault(simpaket, 0)
                scores[simpaket] += similarity
                # Sum of all the similarities
                #totalSim.setdefault(simpaket, 0)
                #totalSim[simpaket] += similarity
        except KeyError:
            pass

        # Divide each total score by total weighting to get an average
        #rankings=[(score/totalSim[item],item) for item,score in scores.items( )]
        rankings=[(score,item) for item,score in scores.items( )]

    # Return the rankings from highest to lowest
    rankings.sort( )
    rankings.reverse( )
    return rankings
