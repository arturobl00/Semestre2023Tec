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
RColorBajo = np.array([0, 100, 20], np.uint8)
RColorAlto = np.array([10, 255, 255], np.uint8)
VColorBajo = np.array([50, 100, 20], np.uint8)
VColorAlto = np.array([70, 255, 255], np.uint8)
AColorBajo = np.array([110, 100, 20], np.uint8)
AColorAlto = np.array([130, 255, 255], np.uint8)

while True:
    #Declaramos 2 variables ret imagen, frame el fotograma
    ret,frame = cam.read()
    #Validamos que ret tenga un valor que mostrar
    if ret==True:
        #Convertimos la imagen original de BGR a una imagen HSV
        frameHSV = cv2.cvtColor(frame,cv2.COLOR_BGR2HSV)
        #Rangos Se mezclan la decteccion el rango inical y el final
        RmaskColor = cv2.inRange(frameHSV,RColorBajo,RColorAlto)
        VmaskColor = cv2.inRange(frameHSV,VColorBajo,VColorAlto)
        AmaskColor = cv2.inRange(frameHSV,AColorBajo,AColorAlto)

        #Es una mascara que solo muestra la presencia del color o la imagen de color
        Rmaskvis = cv2.bitwise_and(frame, frame, mask= RmaskColor)
        Vmaskvis = cv2.bitwise_and(frame, frame, mask= VmaskColor)
        Amaskvis = cv2.bitwise_and(frame, frame, mask= AmaskColor)
       
        cv2.imshow('CamaraNormal', frame)
        cv2.imshow('CamaraRojo',Rmaskvis)
        cv2.imshow('CamaraVerde',Vmaskvis)
        cv2.imshow('CamaraAzul',Amaskvis)
                
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

#Refresco la memoria
cam.release()
#Cierro la Ventana y termino aplicacion
cv2.destroyAllWindows()



