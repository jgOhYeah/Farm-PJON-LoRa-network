orig = open("20210123_1710.csv")
after = open("20210123_Afterrestore.csv")
output = open("output.csv", "w")

origline = orig.readline()
while origline:
    afterline = after.readline()
    if origline != afterline:
        output.write(origline)
        print("'{}' != '{}'".format(origline.strip(), afterline.strip()))
    origline = orig.readline()
print(origline)
orig.close()
after.close()
output.close()
