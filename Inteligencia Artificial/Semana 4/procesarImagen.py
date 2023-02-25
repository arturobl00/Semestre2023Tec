import cv2
import numpy as np

imagen = cv2.imread("fotojoven.jpg")
cv2.imshow("Foto Original", imagen)
#declarar una variable y crear matriz de 300x300 en 
# 3 dimenciones para mostrar el resultado
#vertical, horizontal y ventana
#Declaramos BGR para tener un contenedor
bgr = np.zeros((200,200,3),dtype=np.uint8)
bgr[:,:,:]=(0,255,245)
cv2.imshow("Ventana BGR", bgr)
#Manejo de Tonos de BGR
bgr = imagen
c1 = bgr[:,:,0]
c2 = bgr[:,:,1]
c3 = bgr[:,:,2]
#ahora creamos es stack de tonos
cv2.imshow('Imagen en BGR con Tonos',np.hstack([c1,c2,c3]))
cv2.waitKey(0)
cv2.destroyAllWindows()
