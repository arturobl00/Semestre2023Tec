# Importamos las librerias
import cv2

# Leemos los pesos y la arquitectura
model = 'pose_deploy_linevec_faster_4_stages.prototxt'
pesos = 'pose_iter_160000.caffemodel'

# Definimos el numero de puntos y sus uniones
numpuntos = 15
pares = [[0,1], [1,2], [2,3], [3,4], [1,5], [5,6], [6,7], [1,14], [14,8], [8,9], [9,10], [14,11], [11,12], [12,13]]

# Leemos nuestros pesos y arquitectura
net = cv2.dnn.readNetFromCaffe(model, pesos)

# Creamos la Video Captura
cap = cv2.VideoCapture(1)

# Inicializamos variables
p = False
e = False

# Creamos un ciclo para ejecutar nuestros Frames
while True:
    # Leemos los fotogramas
    ret, frame = cap.read()

    # Corregimos color
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    # Extraemos ancho y alto
    anchoframe = frame.shape[1]
    altoframe = frame.shape[0]

    # Preprocesamos nuestros frames
    TamEntNet = (368,368)
    blob = cv2.dnn.blobFromImage(rgb, 1.0 / 255, TamEntNet, (0,0,0), swapRB = True, crop = False)

    # Entregamos la imagenprocesada a la CNN
    net.setInput(blob)

    # Extraemos info
    output = net.forward()

    # Escalamos la salida al tamaño de nuestros frames
    scalex = anchoframe / output.shape[3]
    scaley = altoframe / output.shape[2]

    # Lista donde almacenaremos los puntos
    puntos = []

    # Umbral
    umbral = 0.1

    # Extraemos las coordenadas de los puntos
    for i in range(numpuntos):
        # Obtenemos el mapa de probabilidades
        probmap = output[0, i, :, :]

        # Encontramos su ubicacion
        minVal, prob, minLoc, point = cv2.minMaxLoc(probmap)

        # Escalamos los puntos
        x = scalex * point[0]
        y = scaley * point[1]

        # Si superamos el umbral lo almacenamos
        if prob > umbral:
            # Agregamos el punto
            puntos.append((int(x), int(y)))
        else:
            puntos.append(None)
    print(p,e)

    # Elegimos si queremos puntos o esqueleto
    # Dibujamos los puntos
    if p == True:
        # Iteramos
        for i, pu in enumerate(puntos):
            # Dibujamos
            cv2.circle(frame, pu, 8, (255,0,255), thickness = -1, lineType= cv2.FILLED)
            cv2.putText(frame, "{}".format(i), pu, cv2.FONT_HERSHEY_SIMPLEX, 1, (0,255,0), 2, lineType = cv2.LINE_AA)

    # Dibujamos esqueleto
    if e == True:

        # Iteramos
        for par in pares:
            # Extraemos los pares
            parteA = par[0]
            parteB = par[1]

            # Si tenemos hay coincidenciasen los pares
            if puntos[parteA] and puntos[parteB]:
                # Dibujamos
                cv2.line(frame, puntos[parteA], puntos[parteB], (0,255,255), 2)
                cv2.circle(frame, puntos[parteA], 8, (255,0,0), thickness = -1, lineType = cv2.FILLED)

    # Mostramos los Frames
    cv2.imshow("VIDEO CAPTURA", frame)

    # Cerramos con lectura de teclado
    t = cv2.waitKey(1)
    if t == 27:
        break

    # Si queremos dibujar los puntos
    if t == 112 or t == 80:
        p = True
        e = False

    # Si queremos dibujar los puntos
    if t == 101 or t == 69:
        p = False
        e = True

# Liberamos la VideoCaptura
cap.release()
# Cerramos la ventana
cv2.destroyAllWindows()