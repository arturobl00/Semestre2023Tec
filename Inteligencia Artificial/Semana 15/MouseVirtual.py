#------------------------------ Importamos las librerias ----------------------------------------
import cv2
import numpy as np
import SeguimientoManos as sm  #Programa que contiene la deteccion y seguimiento de manos
import autopy  #Libreria que nos va a permitir manipular el mouse

#---------------------------------Declaracion de variables---------------------------------------
anchocam, altocam = 640, 480
cuadro = 100 #Rango donde podemos interactura
anchopanta, altopanta = autopy.screen.size() #Obtenemos las dimensiones de nuestra pantalla
sua = 5
pubix, pubiy = 0,0
cubix, cubiy = 0,0
#print(anchopanta, anchocam)

#----------------------------------- Lectura de la camara----------------------------------------
cap = cv2.VideoCapture(0)
cap.set(3,anchocam)  #Definiremos un ancho y un alto definido para siempre
cap.set(4,altocam)

#------------------------------------ Declaramos el detector -----------------------------
detector = sm.detectormanos(maxManos=1) #Ya que solo vamos a utilizar una mano

while True:
    #----------------- Vamos a encontrar los puntos de la mano -----------------------------
    ret, frame = cap.read()
    frame = detector.encontrarmanos(frame)  #Encontramos las manos
    lista, bbox = detector.encontrarposicion(frame) #Mostramos las posiciones

    #-----------------Obtener la punta del dedo indice y corazon----------------------------
    if len(lista) != 0:
        x1, y1 = lista[8][1:]                  #Extraemos las coordenadas del dedo indice
        x2, y2 = lista[12][1:]                 #Extraemos las coordenadas del dedo corazon
        #print(x1,y1,x2,y2)

        #----------------- Comprobar que dedos estan arriba --------------------------------
        dedos = detector.dedosarriba() #Contamos con 5 posiciones nos indica si levanta cualquier dedo
        #print(dedos)
        cv2.rectangle(frame, (cuadro, cuadro), (anchocam - cuadro, altocam - cuadro), (0, 0, 0), 2)  # Generamos cuadro
        #-----------------Modo movimiento: solo dedo indice-------------------------------------
        if dedos[1]== 1 and dedos[2] == 0:  #Si el indice esta arriba pero el corazon esta abajo

            #-----------------> Modo movimiento conversion a las pixeles de mi pantalla-------------
            x3 = np.interp(x1, (cuadro,anchocam-cuadro), (0,anchopanta))
            y3 = np.interp(y1, (cuadro, altocam-cuadro), (0, altopanta))

            #------------------------------- Suavizado los valores ----------------------------------
            cubix = pubix + (x3 - pubix) / sua #Ubicacion actual = ubi anterior + x3 - Pa dividida el valor suavizado
            cubiy = pubiy + (y3 - pubiy) / sua

            #-------------------------------- Mover el Mouse ---------------------------------------
            autopy.mouse.move(anchopanta - cubix,cubiy) #Enviamos las coordenadas al Mouse
            cv2.circle(frame, (x1,y1), 10, (0,0,0), cv2.FILLED)
            pubix, pubiy = cubix, cubiy

        #----------------------------- Comprobar si esta en modo click -------------------------
        if dedos[1] == 1 and dedos[2] == 1:  # Si el indice esta arriba y el corazon tambien
            # --------------->Modo click: encontrar la distancia entre ellos-------------------------
            longitud, frame, linea = detector.distancia(8,12,frame) #Nos entrega la distancia entre el punto 8 y 12
            print(longitud)
            if longitud < 30:
                cv2.circle(frame, (linea[4],linea[5]), 10, (0,255,0), cv2.FILLED)

                #-------------------- Hacemos click si la distancia es corta ---------------------------
                autopy.mouse.click()


    cv2.imshow("Mouse", frame)
    k = cv2.waitKey(1)
    if k == 27:
        break
cap.release()
cv2.destroyAllWindows()
