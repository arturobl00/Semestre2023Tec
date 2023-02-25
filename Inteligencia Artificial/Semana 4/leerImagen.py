import cv2;
#Para leer una imagen declaramos un variable y utilizamos
#El metodo imread en RGB
imagenRGB = cv2.imread("tortuga.jpg")

#Mostrar la imagen en una ventana utilizamos el metodo imshow
cv2.imshow("Mostrar Imagenes", imagenRGB)

#Creamos una pausa
cv2.waitKey(0)
cv2.destroyAllWindows()

#Leer imagen en BGR
imagenBGR = cv2.imread("tortuga.jpg",0)

#Mostrar la imagen en una ventana utilizamos el metodo imshow
cv2.imshow("Mostrar Imagenes", imagenBGR)

#Creamos una pausa
cv2.waitKey(0)
cv2.destroyAllWindows()

