"""
Interfaz de consola
"""
from experto_general.engine import Engine
from tkinter import messagebox

# Motor como variable global
engine = Engine()


def insertar(nombre, prop):
    if nombre and prop:
        entry = engine.base.get_or_add_entry(nombre)
        entry.get_or_add_prop(prop)
        print(f"Entrada agregada: {entry}")
    else:
        print("No se admiten vacíos")
        messagebox.showinfo(message="No se admiten valores vacíos", title="Aviso")


def get_base_entries():
    return engine.base.entries


def guardar(entrada):
    if entrada:
        engine.base.to_json(entrada.strip())
        messagebox.showinfo(message="El archivo fue guardado con éxito", title="Guardado")
    else:
        messagebox.showinfo(message="Elige un nombre para el archivo", title="Guardado")


def cargar(entrada):
    if entrada:
        try:
            engine.base.from_json(entrada.strip())
            messagebox.showinfo(message="El archivo fue cargado con éxito", title="Cargado")
        except KeyError:
            messagebox.showinfo(message="Archivo inválido o con formato incorrecto", title="Cargado")

    else:
        messagebox.showinfo(message="Elige un nombre del archivo a cargar", title="Guardado")
