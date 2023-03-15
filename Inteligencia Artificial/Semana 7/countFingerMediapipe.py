import cv2
import mediapipe as mp

mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles
mp_hands = mp.solutions.hands

cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)

with mp_hands.Hands(
    static_image_mode = False,
    max_num_hands = 1,
    min_detection_confidence = 0.5) as hands:

    while cap.isOpened():
        success, image = cap.read()
        if not success:
            break

        # Convierte la imagen de BGR a RGB
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        image = cv2.flip(image,1)

        # Para detectar manos
        results = hands.process(image)

        # Dibuja puntos en la imagen
        #mp_drawing.draw_landmarks(image, results.hand_landmarks, mp_hands.HAND_CONNECTIONS)

        # Contar dedos levantados
        count = 0
        if results.multi_hand_landmarks:
            for hand_landmarks in results.multi_hand_landmarks:
                mp_drawing.draw_landmarks(image, hand_landmarks, mp_hands.HAND_CONNECTIONS)

                thumb = hand_landmarks.landmark[mp_hands.HandLandmark.THUMB_TIP]
                index = hand_landmarks.landmark[mp_hands.HandLandmark.INDEX_FINGER_TIP]
                middle = hand_landmarks.landmark[mp_hands.HandLandmark.MIDDLE_FINGER_TIP]
                ring = hand_landmarks.landmark[mp_hands.HandLandmark.RING_FINGER_TIP]
                pinky = hand_landmarks.landmark[mp_hands.HandLandmark.PINKY_TIP]
                
                if thumb.y < index.y and thumb.x < index.x:
                    count += 1
                if index.y < middle.y and index.x < middle.x:
                    count += 1
                if middle.y < ring.y and middle.x < ring.x:
                    count += 1
                if ring.y < pinky.y and ring.x < pinky.x:
                    count += 1

        # Muestra el número de dedos levantados en la imagen
        cv2.putText(image, str(count), (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2, cv2.LINE_AA)

        # Convierte la imagen de nuevo de RGB a BGR
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

        # Muestra la imagen
        cv2.imshow('Contador de dedos', image)
        if cv2.waitKey(5) & 0xFF == 27:
            break

cap.release()
cv2.destroyAllWindows()
