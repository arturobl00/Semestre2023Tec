class Property:
    """
    Clase de Propiedades
    """

    def __init__(self, name: str):
        """
        Crea una nueva propiedad

        :param name: Identificador de la propiedad
        """
        self.name = name.strip()

    def is_equal(self, name: str) -> bool:
        """
        Determina si una cadena es igual al nombre de la propiedad

        :param name: La cadena a comparar
        :return: Verdadero si la cadena y el nombre son iguales o similares
        """
        return self.name.lower() == name.lower().strip()

    def __eq__(self, item):
        """
        Comparar igualdad con otro objeto

        :param item: El objeto con el que se compara
        :return: Verdadero si los objetos son de la misma instancia y tienen el mismo nombre
        """
        if isinstance(item, Property):
            return self.is_equal(item.name)
        return False
