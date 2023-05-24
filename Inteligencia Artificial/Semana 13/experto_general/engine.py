from typing import List
from experto_general.base import BaseConocimientos
from experto_general.entry import Entry
from experto_general.property import Property
from experto_general.response import Response


# Método temporal para usar sólo con CLI
def _get_user_response(prop: Property) -> Response:
    """
    Obtener confirmación del usuario si cierta propiedad debe ser considerada

    :param prop: Propiedad a preguntar
    :return: Respuesta de confirmación o rechazo
    """
    prompt_str = "¿Es/Tiene " + prop.name + "? (s/n): "
    response = input(prompt_str).strip().lower()

    while response != 's' and response != 'n':
        prompt_str = "Ingrese una respuesta válida (s/n): "
        response = input(prompt_str).strip().lower()

    if response == 's':
        return Response.YES
    return Response.NO


class Engine:
    """
    Motor de inferencia
    """

    def __init__(self):
        """
        Inicializa una instancia de motor de inferencia
        """
        self.base = BaseConocimientos()
        self.accepted_properties: List[Property] = []
        self.denied_properties: List[Property] = []
        self.response: Response = Response.NO
        self.result: Entry or None = None

    def start(self) -> Entry or None:
        """
        Obtener una entrada en base a propiedades que ingrese el usuario

        :return: Entrada que coincida con las propiedades. None si no coincide ninguna
        """
        self.accepted_properties: List[Property] = []
        self.denied_properties: List[Property] = []

        for entry in self.base.entries:

            correct_entry = True

            if self._check_rule_2(entry) is False:
                continue

            if self._check_rule_3(entry) is False:
                continue

            for prop in entry.properties:
                if self._check_rule_1(prop) is False:
                    continue

                response = _get_user_response(prop)
                if response == Response.YES:
                    self.accepted_properties.append(prop)
                else:
                    self.denied_properties.append(prop)
                    correct_entry = False
                    break

            if correct_entry is True:
                return entry

        return None

    def generate(self):
        """
        Genera una lista de propiedades a preguntar, esperando una iteración del
        generador para continuar.

        Entre propiedades, se recibe la propiedad response del objeto como respuesta a
        la pregunta de la propiedad, y al finalizar el resultado se almacena en result
        """
        self.accepted_properties: List[Property] = []
        self.denied_properties: List[Property] = []

        for entry in self.base.entries:

            correct_entry = True

            if self._check_rule_2(entry) is False:
                continue

            if self._check_rule_3(entry) is False:
                continue

            for prop in entry.properties:
                if self._check_rule_1(prop) is False:
                    continue

                yield prop

                if self.response == Response.YES:
                    self.accepted_properties.append(prop)
                else:
                    self.denied_properties.append(prop)
                    correct_entry = False
                    break

            if correct_entry is True:
                self.result = entry
                yield None

        self.result = None
        yield None

    def set_response(self, response: Response):
        self.response = response

    def get_result(self) -> Entry or None:
        return self.result

    def _check_rule_1(self, prop: Property) -> bool:
        """
        Verificar 1ra regla. Que una propiedad no haya sido preguntada anteriormente

        :param prop:
        :return: Verdadero si se cumple la regla
        """        
        return (prop not in self.accepted_properties and
                prop not in self.denied_properties)

    def _check_rule_2(self, entry: Entry) -> bool:
        """
        Verificar 2da regla. Que una entrada tenga todas las propiedades requeridas

        :param entry:
        :return: Verdadero si se cumple la regla
        """
        for prop in self.accepted_properties:
            if prop not in entry.properties:
                return False
        return True

    def _check_rule_3(self, entry: Entry) -> bool:
        """
        Verificar 3ra regla. Que una entrada no tenga propiedades rechazadas

        :param entry:
        :return: Verdadero si se cumple la regla
        """
        for prop in self.denied_properties:
            if prop in entry.properties:
                return False
        return True
