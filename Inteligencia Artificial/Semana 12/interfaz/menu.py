import tkinter as tk
import interfaz.insertarbase as insertar_base
import interfaz.guardarbase as guardar_base
import interfaz.consultarbase as consultar_base


class Interfaz(tk.Frame):
    def __init__(self):
        root = tk.Tk()
        super().__init__(root)
        root.geometry('400x200')
        root.title('SE para selección de agares')
        root.resizable(width=False, height=False)
        self.master = root
        self.pack()

        self.lbl_base = tk.Label(self, text="Sistema Experto Agares")
        self.lbl_base.pack(side="top")
        self.lbl_base.config(font=("Helvetica", 24))

        self.txt_insertar = tk.Button(self, text="Insertar/Visualizar", width=50, command=insertar_base.InsertarBase)
        self.txt_insertar.pack(side="top", padx=5, pady=5)

        self.txt_consultar = tk.Button(self, text="Consultar", width=50, command=consultar_base.ConsultarBase)
        self.txt_consultar.pack(side="top", padx=5, pady=5)

        self.txt_guardar = tk.Button(self, text="Cargar/Guardar", width=50, command=guardar_base.GuardarBase)
        self.txt_guardar.pack(side="top", padx=5, pady=5)

        self.quit = tk.Button(self, text="QUIT", width=50, fg="red", command=self.master.destroy)
        self.quit.pack(side="bottom", padx=5, pady=5)
