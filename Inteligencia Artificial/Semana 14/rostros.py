import cv2
import numpy as np

cam = cv2.VideoCapture(1)
human_cascade = cv2.CascadeClassifier('haarcascade_fullbody.xml')

while True:
    ret, frame = cam.read()
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    human = human_cascade.detectMultiScale(gray,
	1.1, 4)

    for (x,y,w,h) in human:
	    cv2.rectangle(frame,(x,y),(x+w,y+h),(0,0,220),2)

    cv2.imshow('Video', frame)
    
    if cv2.waitKey(25) & 0xFF == ord('q'):
          break
    
cam.release()
cv2.destroyAllWindows()


