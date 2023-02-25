import cv2
cam = cv2.VideoCapture(1)
print(cam)
#Variable para salidad de video
salida = cv2.VideoWriter('pruebaColor.avi',
                         cv2.VideoWriter_fourcc(*'XVID'),
                         24.0,
                         (640,480)
                         )
print(salida)

while(cam.isOpened()):
    #usamos dos parametros ret que es la camara e imagen
    ret,imagen=cam.read()
    #si la camara esta activa mostramos el video en una ventana
    if ret == True:
        cv2.imshow('RED CAM',imagen)
        salida.write(imagen)
        #condición para terminar el proceso al precionar la tecla s
        if cv2.waitKey(1) & 0xFF == ord('s'):
            break

#Limpiar Buffer de Video
cam.release()
salida.release()
cv2.destroyAllWindows()

#Reproducir un Archivo de Video
#El proceso de reproducir un archivo de video es similar
#al de capurar un video medite webcam
cam = cv2.VideoCapture('pruebaColor.avi')
#Declarar ciclo para reproducción
while(cam.isOpened()):
    #usamos dos parametros ret que es la camara e imagen
    ret,imagen=cam.read()
    #si Tenemos video
    if ret == True:
        #Mostrar el video en una pantalla
        cv2.imshow('Video Archivo',imagen)
        #condición para terminar el proceso al precionar la tecla s
        if cv2.waitKey(24) & 0xFF == ord('s'):
            break
    else: 
        break

#Limpiar Buffer de Video
cam.release()
cv2.destroyAllWindows()