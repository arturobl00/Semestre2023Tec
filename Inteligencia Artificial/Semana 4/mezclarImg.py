import cv2
#Leer imagenes
fotoJoven = cv2.imread("fotojoven.jpg")
fotoMayor = cv2.imread("fotomayor.jpeg")
#Crear variable y mezclar fotos
mixFotos = cv2.addWeighted(fotoJoven, 0.5, fotoMayor, 0.5, 0.0)
#Mostrar el Mix
cv2.imshow("Imagen Mix", mixFotos)
cv2.waitKey(0)
cv2.destroyAllWindows()