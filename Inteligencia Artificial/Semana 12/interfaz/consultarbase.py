import tkinter as tk
import tkinter.messagebox as messagebox
from experto_general.response import Response
from acciones import engine


class ConsultarBase(tk.Frame):

    def __init__(self):
        self.master = tk.Toplevel()
        super().__init__(self.master)

        self.master.geometry('380x120')
        self.master.title('Consultar al sistema')
        self.master.resizable(width=False, height=False)

        self.lbl_question = tk.Label(self, text="PREGUNTA")
        self.lbl_question.pack(side="top", pady=20)
        self.lbl_question.config(font=("Helvetica", 12))

        self.btn_yes = tk.Button(self, text="Sí", width=20, command=self._send_yes)
        self.btn_yes.pack(side="left", padx=5, pady=5)

        self.btn_no = tk.Button(self, text="No", width=20, command=self._send_no)
        self.btn_no.pack(side="right", padx=5, pady=5)

        self.pack()
        self.questions = engine.generate()
        self._get_question(Response.NO)

    def _send_yes(self):
        self._get_question(Response.YES)

    def _send_no(self):
        self._get_question(Response.NO)

    def _get_question(self, response: Response):
        try:
            engine.set_response(response)
            question = next(self.questions)

            if question is not None:
                self.lbl_question.config(text=f"¿{question.name}?")
            else:
                self._finished()

        except StopIteration:
            self._finished()

    def _finished(self):
        if engine.result is None:
            messagebox.showerror("Error",
                                 "No se encontró ninguna entrada que coincida con las propiedades ingresadas")
        else:
            reason = f"Sugerido porque:\n"
            for prop in engine.result.properties:
                reason += f"- {prop.name}\n"
            messagebox.showinfo("Recomendación",
                                f"Se recomienda: {engine.result.name}\n\n{engine.result.description}\n\n" + reason)

        self.master.destroy()
