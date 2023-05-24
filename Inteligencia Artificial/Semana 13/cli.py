"""
Interfaz de consola
"""
from experto_general.engine import Engine


# Motor como variable global
engine = Engine()


def _1_insertar():
    entrada = input("Nombre de la entrada: ")
    entry = engine.base.get_or_add_entry(entrada)
    print("Escriba las propiedades de la entrada, una por línea. Deje una línea vacía para terminar")
    while entrada != "":
        prop = input("> ").strip()
        if len(prop) == 0:
            break
        entry.get_or_add_prop(prop)

    print(f"Entrada agregada: {entry}")


def _2_consultar():
    entry = engine.start()
    if entry is None:
        print("No se encontró ninguna entrada que coincida con las propiedades ingresadas")
    else:
        print(f"El resultado de la consulta es: {entry}")


def _3_ver():
    print(engine.base)


def _4_guardar():
    entrada = input("Nombre de archivo: ")
    engine.base.to_json(entrada.strip())
    print("Guardado con éxito")


def _5_cargar():
    entrada = input("Nombre de archivo: ")
    try:
        engine.base.from_json(entrada.strip())
    except KeyError as e:
        print("Archivo inválido o con formato incorrecto:", e)


def menu():
    while True:
        print("1. Introducir objeto")
        print("2. Consultar")
        print("3. Ver base")
        print("4. Guardar")
        print("5. Cargar desde archivo")
        print("6. Salir")
        print("")

        entrada = input("> ").strip()

        if entrada == "6":
            break
        elif entrada == "1":
            _1_insertar()
        elif entrada == "2":
            _2_consultar()
        elif entrada == "3":
            _3_ver()
        elif entrada == "4":
            _4_guardar()
        elif entrada == "5":
            _5_cargar()
        else:
            print("Opción inválida")

        print("")
