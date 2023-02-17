#Importar la librerias
import cv2
import numpy as np

#Activar la WebCam usamos el parametro 0 como defaul si tenemos mas de una camara usamos el
#numero consecutivo ejemplo si tengo 2 camaras el 0 sera la camara 1 y el 1 la camara 2
cam = cv2.VideoCapture(1)

#Validación de Camaaaara
if not cam.isOpened():
    print("Cannot open camera")
    exit()

#Crear un Ciclo para la captura de video
while True:
    #Declaramos 2 variables ret imagen, frame el fotograma
    ret,frame = cam.read()
    #Validamos que ret tenga un valor que mostrar
    if ret==True:
        #Con imshow mostramos una ventana con un titulo y un contenido
        cv2.imshow('frame', frame)
        #Funcion de cierre cuestiono si preciona la tecla q
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

#Refresco la memoria
cam.release()
#Cierro la Ventana y termino aplicacion
cv2.destroyAllWindows()



