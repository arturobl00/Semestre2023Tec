from typing import List
from experto_general.property import Property


class Entry:
    """
    Clase de Objetos
    """

    def __init__(self, name: str):
        """
        Crea una entrada vacía de la base de conocimientos

         :param name: Identificador de la entrada
        """
        self.properties: List[Property] = []
        self.name = name.strip()
        self.description = ""

    def get_or_add_prop(self, name: str) -> Property:
        """
        Agrega una propiedad al objeto, excepto si la propiedad ya existía

        :param name:
        :return: La nueva propiedad o la existente, si ya existía
        """
        for prop in self.properties:
            if prop.is_equal(name):
                return prop

        prop = Property(name)
        self.properties.append(prop)
        return prop

    def is_equal(self, name: str) -> bool:
        """
        Determina si una cadena es igual al nombre de la entrada

        :param name: La cadena a comparar
        :return: Verdadero si la cadena y el nombre son iguales o similares
        """
        return self.name.lower() == name.lower().strip()

    def __str__(self):
        """
        Mostrar la entrada como una cadena, con fines de depuración

        :return: Una cadena con la entrada y sus propiedades
        """
        res = f'Entry "{self.name}":'
        if len(self.description) > 0:
            res += f"\n\t{self.description}"
        for prop in self.properties:
            res += f"\n\t- {prop.name}"
        return res
