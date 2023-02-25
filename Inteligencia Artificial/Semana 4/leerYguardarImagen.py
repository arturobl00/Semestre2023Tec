import cv2
#Leer Imagen en BGR
imagenBGR = cv2.imread("tortuga.jpg",0)
#Guardar la Imagen en formato BGR
imgProcesada = cv2.imwrite("tortugaGris.jpg",imagenBGR)
#Leer la imagen guardada
imgTotugaGris = cv2.imread("tortugaGris.jpg")
#Mostrar el resultado
cv2.imshow("Imagen Guardada", imgTotugaGris)
#Pausa y Termino
cv2.waitKey(0)
cv2.destroyAllWindows
