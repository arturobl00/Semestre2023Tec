import cv2
import numpy as np
import imutils

faceClassif = cv2.CascadeClassifier('haarcascade_frontalface_default.xml')

cam = cv2.VideoCapture(1)
#Algoritmo de substraccion de fondo
fgbg = cv2.bgsegm.createBackgroundSubtractorMOG()
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
peope_counter = 0

while True:
    ret, frame = cam.read()
    #imutils se usa para redimencionar el tamaño de la ventana 
    frame = imutils.resize(frame, width=800, height=600)

     # Especificamos los puntos extremos del área a analizar
    #area_pts = np.array([[330, 16], [frame.shape[1]-80, 16], [frame.shape[1]-80, 445], [330, 445]])
    

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    faces = faceClassif.detectMultiScale(gray,
	scaleFactor=1.1,
	minNeighbors=5,
	minSize=(30,30),
	maxSize=(200,200))
    
    

    #Area de Detección de elementos Recuadro
                        #Punto 1      Punto 2                   Punto 2F                  Punto 1F 
    area_pts = np.array([[250, 110], [frame.shape[1]-350, 110], [frame.shape[1]-350, 530], [250, 530]])

    #Dibujamos el rectangulo y la linea de cruze
    #cv2.drawContours(frame, [area_pts], -1, (255, 0, 0), 2)
    #cv2.line(frame, (450, 16), (450, 445), (255, 0, 0), 1)
    #cv2.line(frame, (50, 16), (50, 445), (255, 0, 0), 1)

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
            #Rectangulos de detección de objetos Rojo
            cv2.rectangle(frame, (x,y), (x+w,y+h), (0,0,255), 1)
    
            #Dibujar una linea verde cada que el auto pasa en las coordenadas de la linea amarilla
            #if 440 < (x + w) < 460:
            if 355 < (x + w) < 365:
                peope_counter = peope_counter + 1
                cv2.line(frame, (350, 110), (350, 530), (0, 255, 0), 3)

    # Visualización del conteo de autos
    #Recuadro de Detección o Cerca
    cv2.drawContours(frame, [area_pts], -1, (0, 255, 255), 3)
    #cv2.line(frame, (450, 16), (450, 445), (0, 255, 255), 1)
    #Linea Amarilla indicador
    cv2.line(frame, (350, 110), (350, 530), (0, 255, 255), 1)
    #Rectangulo con el numero de autos
    #cv2.rectangle(frame, (frame.shape[1]-200, 215), (frame.shape[1]-100, 270), (0, 255, 0), 2)
    cv2.putText(frame, "Cruze Objetos", (frame.shape[1]-320, 250),
                cv2.FONT_HERSHEY_SIMPLEX, 1.2, (200,0,0), 1)
    
    cv2.putText(frame, str(peope_counter), (frame.shape[1]-200, 300),
                cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0,255,0), 1)
    
    cv2.imshow('Video Puerta', frame)
    #cv2.imshow('Segmento', image_area)
    #cv2.imshow('Segmento2', fgmask)

    k = cv2.waitKey(1) & 0xFF
    if k == 27 : break

cam.release()
cv2.destroyAllWindows()