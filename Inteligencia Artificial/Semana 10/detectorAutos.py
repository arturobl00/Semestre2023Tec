import cv2
import numpy as np
import imutils

cam = cv2.VideoCapture('video.mp4')
#Algoritmo de substraccion de fondo
fgbg = cv2.bgsegm.createBackgroundSubtractorMOG()
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
car_counter = 0


while True:
    ret, frame = cam.read()
    #imutils se usa para redimencionar el tamaño de la ventana 
    frame = imutils.resize(frame, width=800, height=600)

     # Especificamos los puntos extremos del área a analizar
    area_pts = np.array([[330, 16], [frame.shape[1]-80, 16], [frame.shape[1]-80, 445], [330, 445]])

    #Dibujamos el rectangulo y la linea de cruze
    cv2.drawContours(frame, [area_pts], -1, (255, 0, 255), 2)
    cv2.line(frame, (450, 16), (450, 445), (0, 255, 255), 1)

    if ret == False : break

    # Con ayuda de una imagen auxiliar, determinamos el área
    # sobre la cual actuará el detector de movimiento
    imAux = np.zeros(shape=(frame.shape[:2]), dtype=np.uint8)
    imAux = cv2.drawContours(imAux, [area_pts], -1, (255), -1)
    image_area = cv2.bitwise_and(frame, frame, mask=imAux)

    #Extraccion de elemeto auto sobre image_area
    fgmask = fgbg.apply(image_area)
    #Mejorar la imagen para que sea solida en contorno y relleno
    fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_OPEN, kernel)
    fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_CLOSE, kernel)
    fgmask = cv2.dilate(fgmask, None, iterations=5)    

    #Encontramos los contornos presentes de fgmask, para luego basándonos
    # en su área poder determinar si existe movimiento (autos)
    cnts = cv2.findContours(fgmask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)[0]
    #Ciclo para contar los autos que pasan por la linea
    for cnt in cnts:
        if cv2.contourArea(cnt) > 500:
            x, y, w, h = cv2.boundingRect(cnt)
            cv2.rectangle(frame, (x,y), (x+w,y+h), (0,255,255), 1)
    
            #Dibujar una linea verde cada que el auto pasa en las coordenadas de la linea amarilla
            if 440 < (x + w) < 460:
                car_counter = car_counter + 1
                cv2.line(frame, (450, 16), (450, 445), (0, 255, 0), 3)

    # Visualización del conteo de autos
    cv2.drawContours(frame, [area_pts], -1, (255, 0, 255), 2)
    cv2.line(frame, (450, 16), (450, 445), (0, 255, 255), 1)
    #Rectangulo con el numero de autos
    cv2.rectangle(frame, (frame.shape[1]-70, 215), (frame.shape[1]-5, 270), (0, 255, 0), 2)
    cv2.putText(frame, str(car_counter), (frame.shape[1]-55, 250),
                cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0,255,0), 2)
    
    cv2.imshow('Video Autopista', frame)
    #cv2.imshow('Segmento', image_area)
    #cv2.imshow('Segmento2', fgmask)

    k = cv2.waitKey(1) & 0xFF
    if k == 27 : break

cam.release()
cv2.destroyAllWindows()