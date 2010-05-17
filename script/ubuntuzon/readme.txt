#Go in the python command line in the folder in which are the files
python
#the first steps you must do only one time
#notice: the functions are comment in the source code
>>> import communtu
>>> communtu.generate_paketlist()
#all users list
>>> users=communtu.loaduserdata()
#here is the user toddy
>>> toddy=communtu.loaduser(file("pakete/toddy"))
>>> import recommendations
#the packages where load in simitiems or better in productiv in the database
>>> simitiems=recommendations.calculateSimilarItems(users)
#and here is the output
>>> recommendations.getRecommendedItems(toddy,simitiems)
