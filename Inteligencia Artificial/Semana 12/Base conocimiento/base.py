from typing import List
from experto_general.entry import Entry
from io import open
import json


JSON_LATEST = 1


class BaseConocimientos:
    """
    Clase de la base de conocimientos del sistema experto
    """

    def __init__(self):
        """
        Crea una base de conocimientos vacía
        """
        self.entries: List[Entry] = []
        self.description = "Base de conocimientos"

    def from_json(self, filename: str):
        """
        Carga una base de conocimientos a partir de un archivo .json

        :param filename: El nombre del archivo
        :return: La instancia de la base de conocimiento (self)
        """
        with open(filename, 'r', encoding='utf8') as f:
            data = f.read()

        obj = json.loads(data)

        if obj['__v'] != JSON_LATEST:
            raise ValueError("Actualizar JSON a nueva versión")

        self.description = obj['description']

        for json_entry in obj['entries']:
            entry = self.get_or_add_entry(str(json_entry['name']))
            entry.description = str(json_entry['description'])
            for json_prop in json_entry['props']:
                entry.get_or_add_prop(str(json_prop))

        return self

    def to_json(self, filename: str):
        """
        Guarda la base de conocimientos a un archivo .json

        :param filename: El nombre del archivo
        :return: Cadena de los datos guardados en JSON
        """
        obj = {'__v': JSON_LATEST, 'description': self.description, 'entries': []}

        for entry in self.entries:
            json_entry = {'name': entry.name, 'description': entry.description, 'props': []}
            for prop in entry.properties:
                json_entry['props'].append(prop.name)
            obj['entries'].append(json_entry)

        data = json.dumps(obj)
        with open(filename, 'w', encoding='utf8') as f:
            f.write(data)
        return data

    def get_or_add_entry(self, name: str):
        """
        Obtiene una entrada de la base de conocimiento, o la agrega si no existe

        :param name:
        :return: La nueva propiedad o la existente, si ya existía
        """
        for entry in self.entries:
            if entry.is_equal(name):
                return entry

        entry = Entry(name)
        self.entries.append(entry)
        return entry

    def __str__(self):
        """
        Mostrar la base como una cadena, con fines de depuración

        :return: Una cadena con la base y sus entradas
        """
        res = f"[{self.description}]"
        for entry in self.entries:
            res += f"\n{entry}\n"
        return res
