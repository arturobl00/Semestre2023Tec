#Importar la librerias
import cv2
import numpy as np

#Activar la WebCam usamos el parametro 0 como defaul si tenemos mas de una camara usamos el
#numero consecutivo ejemplo si tengo 2 camaras el 0 sera la camara 1 y el 1 la camara 2
cam = cv2.VideoCapture(0)

#Validación de Camara
if not cam.isOpened():
    print("Cannot open camera")
    exit()

#Nota el primer elemento es H el segundo es S y el tercero V
#Nota S y V se quedan fijos
ColorBajo = np.array([50, 100, 20], np.uint8)
ColorAlto = np.array([70, 255, 255], np.uint8)

while True:
    #Declaramos 2 variables ret imagen, frame el fotograma
    ret,frame = cam.read()
    #Validamos que ret tenga un valor que mostrar
    if ret==True:
        #Convertimos la imagen original de BGR a una imagen HSV
        frameHSV = cv2.cvtColor(frame,cv2.COLOR_BGR2HSV)
        #Rangos Se mezclan la decteccion el rango inical y el final
        maskColor = cv2.inRange(frameHSV,ColorBajo,ColorAlto)
        #Es una mascara que solo muestra la presencia del color o la imagen de color
        maskvis = cv2.bitwise_and(frame, frame, mask= maskColor)
       
        cv2.imshow('CamaraNormal', frame)
        cv2.imshow('CamaraMaskVis',maskvis)
                
        #cv2.imshow('Video con Redvis', maskRedvis)
        #Funcion de cierre cuestiono si preciona la tecla q
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

#Refresco la memoria
cam.release()
#Cierro la Ventana y termino aplicacion
cv2.destroyAllWindows()



