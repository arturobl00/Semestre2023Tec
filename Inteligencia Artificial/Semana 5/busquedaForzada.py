numero = int(input("Ingrese un valor de 4 digitos: "))
print("El valor fue:", numero)
paso = 0

#Algoritmo de busqueda forzada
for x in range(1000, 10000):
    paso = paso + 1
    if x == numero :
        print("Se tardo pasos : ", paso, "Valor de x", x)


