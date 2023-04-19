import cv2
import numpy as np
import imutils
import os   

Datos = 'n'
if not os.path.exists(Datos):
    print('Carpeta Creada: ', Datos)
    os.makedirs(Datos)

cap = cv2.VideoCapture(0)

#Crear un rectangulo o area de captura
x1, y1 = 190, 80
x2, y2 = 450, 398

count = 0

while True:
    ret, frame = cap.read()
    if ret == False: break
    cv2.rectangle(frame,(x1,y1),(x2,y2),(255,0,0),2)
    #Generar una copia del video
    imAux = frame.copy()
    #Recortar el video en las coordenadas del cuadro
    objeto = imAux[y1:y2,x1:x2]
    #Redimiencionar el video para mi modelo
    objeto = imutils.resize(objeto, width=38)

    cv2.imshow('Frame', frame)
    cv2.imshow('Resize', objeto)

    k = cv2.waitKey(1)
    if k == 13:
        break

    if k== ord('s'):
        cv2.imwrite(Datos+'/objeto_{}.jpg'.format(count),objeto)
        print('Imagen Almacena: ', 'objeto_{}.jpg'.format(count))
        count = count + 1

cap.release()
cv2.destroyAllWindows()