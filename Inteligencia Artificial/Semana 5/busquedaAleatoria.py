import random

numero = int(input("Ingrese un valor de 4 digitos: "))
paso = 0
print("El valor fue:", numero)

#Algoritmo de busqueda aleatoria
for x in range(1000, 10000):
    paso = paso+1
    y = random.randint(1000,9999)
    if y == numero :
        print("Se tardo total: ", paso, "ciclo x:", x)



