import os

def main():
    print "==========================="
    times = {}
    for f in os.listdir('timings'):
        myFile = open('timings/' + f, "r")
        (measured, theTime) = myFile.read().split(" ")
        if measured in times:
            times[measured] += float(theTime)
        else:
            times[measured] = float(theTime)
    #print times
    sum = 0.0
    for (k,v) in times.items():
        if k != "total":
           sum += v
           print (str(k) + ": " + str(v)) 
    print "Other:", times['total'] - sum
    print "==========================="
    print "total:", times['total']



if __name__ == "__main__":
    main()
