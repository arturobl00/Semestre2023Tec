#Importar la librerias
import cv2
import numpy as np

#Activar la WebCam usamos el parametro 0 como defaul si tenemos mas de una camara usamos el
#numero consecutivo ejemplo si tengo 2 camaras el 0 sera la camara 1 y el 1 la camara 2
cam = cv2.VideoCapture(1)

#Validación de Camara
if not cam.isOpened():
    print("Cannot open camera")
    exit()

redBajo1 = np.array([0, 100, 20], np.uint8)
redAlto1 = np.array([5, 255, 255], np.uint8)
redBajo2=np.array([175, 100, 20], np.uint8)
redAlto2=np.array([177, 255, 255], np.uint8)
#Crear un Ciclo para la captura de video
while True:
    #Declaramos 2 variables ret imagen, frame el fotograma
    ret,frame = cam.read()
    #Validamos que ret tenga un valor que mostrar
    if ret==True:
        #Convertimos la imagen original de BGR a una imagen HSV
        frameHSV = cv2.cvtColor(frame,cv2.COLOR_BGR2HSV)
        #Rangos Se mezclan
        maskRed1 = cv2.inRange(frameHSV,redBajo1,redAlto1)
        maskRed2 = cv2.inRange(frameHSV,redBajo2,redAlto2)
        maskRed = cv2.add(maskRed1,maskRed2)
        #Con imshow mostramos una ventana con un titulo y un contenido
        cv2.imshow('CamaraNormal', frame)
        #cv2.imshow('CamaraHSV', frameHSV)
        cv2.imshow('CamaraMaskColor',maskRed)

        maskRedvis = cv2.bitwise_and(frame, frame, mask= maskRed)        
        #cv2.imshow('Video con Redvis', maskRedvis)
        #Funcion de cierre cuestiono si preciona la tecla q
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

#Refresco la memoria
cam.release()
#Cierro la Ventana y termino aplicacion
cv2.destroyAllWindows()



