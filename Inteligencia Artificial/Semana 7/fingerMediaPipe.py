import cv2
import mediapipe as mp
import numpy as np

#Declaramos las solucionnes de mediapipe
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles
mp_hands = mp.solutions.hands

cap = cv2.VideoCapture(0)
with mp_hands.Hands(
    static_image_mode = False,
    max_num_hands = 2,
    min_detection_confidence = 0.5) as hands:
  
  while True:
        ban, frame = cap.read()
        if ban == False:
            break
        #Tomamos el alto y ancho de el video
        height, width, _ = frame.shape
        #Usaremos flip para no ver en espejo la imagen
        frame = cv2.flip(frame,1)
        #Cambiamos la imagen de frame a RGB
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        #TOmar datos y los mandamos a result
        result = hands.process(frame_rgb)
        #Cuestiono si tengo algo que procesar o detecto alguna mano
        if result.multi_hand_landmarks is not None:
            #Creo un arreglo con los 21 puntos de la mano que deseo procesar
            #En la documentación consulta los puntos
            #index = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
            index = [4,8,12,16,20] 
            #Ya con los indices creo cv2.circle(frame, (x,y), 5, (0,0,255), -1)un ciclo para dibujar de forma constante lo detectado
            for hand_landmarks in result.multi_hand_landmarks:
                #mp_drawing.draw_landmarks(
                 #   frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)
                
                #Ciclo para mostrar los puntos de la mano
                for (i, points) in enumerate(hand_landmarks.landmark):
                    if i in index:
                        x = int(points.x * width)
                        y = int(points.y * height)
                        cv2.circle(frame, (x,y), 15, (255,0,0), -1)
            
        #Mostrar video procesado
        cv2.imshow("Cam MediaPipe", frame)

        if cv2.waitKey(1) & 0xFF == ord('a'):
            break

cap.realice()
cv2.destroyAllWindows()





