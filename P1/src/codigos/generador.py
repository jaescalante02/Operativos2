import sys
import random

casos = int(raw_input())
print "<processes>"
for i in range(0,casos):
	print "\t<process>"
	print "\t\t<id>"+"p"+str(i)+"</id>"
	size = random.randint(1,400)
	arrival = random.randint(500,10000)
	print "\t\t<item>"
	print "\t\t\t<arrival>"+str(arrival)+"</arrival>"
	print "\t\t\t<size>"+str(size)+"</size>"
	acs  = random.randint(100,2000)
	for k in range(0,acs):
		tmp = random.randint(0,size-1)
		print "\t\t\t<page>"+str(tmp)+"</page>"
	print "\t\t</item>"
	print "\t</process>"

print "</processes>"
