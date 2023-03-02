import cv2
import numpy as np

#Declaramos variable para la captura de video
cap = cv2.VideoCapture(1)

#Determinamos en 2 variables el color rojo
colorInicial = np.array([0,100,20], np.uint8)
colorFinal = np.array([8,255,255], np.uint8)

while True:
  ret,frame = cap.read()
  if ret==True:
    frameHSV = cv2.cvtColor(frame,cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(frameHSV,colorInicial,colorFinal)

    #Proceso para detectar contorno
    contornos,_ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    #Proceso para dibujar contorno detectado con un ciclo
    for c in contornos:
      area = cv2.contourArea(c)
      if area > 3000:
        nuevoContorno = cv2.convexHull(c) #esta funcion elimina picos
        cv2.drawContours(frame, [c], -1, (0,0,255), -1)

    cv2.imshow('Video Detección',frame)
    if cv2.waitKey(1) & 0xFF == ord('s'):
      break

cap.release()
cv2.destroyAllWindows()