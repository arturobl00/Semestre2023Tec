import cv2
import numpy as np

cap = cv2.VideoCapture(1)

RColorBajo = np.array([4, 100, 20], np.uint8)
RColorAlto = np.array([7, 255, 255], np.uint8)

VColorBajo = np.array([40, 100, 20], np.uint8)
VColorAlto = np.array([70, 255, 255], np.uint8)

AColorBajo = np.array([100, 50, 50], np.uint8)
AColorAlto = np.array([130, 255, 255], np.uint8)


while True:
  ret,frame = cap.read()
  if ret==True:
    frameHSV = cv2.cvtColor(frame,cv2.COLOR_BGR2HSV)
    maskR = cv2.inRange(frameHSV,RColorBajo,RColorAlto)
    cv2.imshow("MAsk ROjo", maskR)
    
    maskV = cv2.inRange(frameHSV,VColorBajo,VColorAlto)
    cv2.imshow("MAsk Verde", maskV)

    maskA = cv2.inRange(frameHSV,AColorBajo,AColorAlto)
    cv2.imshow("MAsk Azul", maskA)

    #Proceso para detectar contorno
    Rcontornos,_ = cv2.findContours(maskR, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    Vcontornos,_ = cv2.findContours(maskV, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    Acontornos,_ = cv2.findContours(maskA, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    #Proceso para dibujar contorno detectado con un ciclo
    for c in Rcontornos:
      area = cv2.contourArea(c)
      if area > 1000:
        nuevoContorno = cv2.convexHull(c) #esta funcion elimina picos
        cv2.drawContours(frame, [c], -1, (0,0,255), -1)

    for cv in Vcontornos:
      areav = cv2.contourArea(cv)
      if areav > 3000:
        nuevoContornoV = cv2.convexHull(cv) #esta funcion elimina picos
        cv2.drawContours(frame, [cv], -1, (0,255,0), -1)

    for ca in Vcontornos:
      areaa = cv2.contourArea(ca)
      if areaa > 3000:
        nuevoContornoA = cv2.convexHull(ca) #esta funcion elimina picos
        cv2.drawContours(frame, ca, -1, (255,0,0), -1)

    cv2.imshow('Video Detección',frame)
    if cv2.waitKey(1) & 0xFF == ord('s'):
      break

cap.release()
cv2.destroyAllWindows()