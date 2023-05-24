import tkinter as tk
import acciones


class GuardarBase(tk.Frame):

    def __init__(self):
        root = tk.Toplevel()
        super().__init__(root)
        root.geometry('400x220')
        root.title('Guardar Base de Conocimientos')
        root.resizable(width=False, height=False)
        self.master = root
        self.pack()

        self.lbl_base = tk.Label(self, text="Cargar/Guardar Base")
        self.lbl_base.pack(side="top")
        self.lbl_base.config(font=("Helvetica", 24))

        self.lbl_file = tk.Label(self, text="Nombre del archivo:")
        self.lbl_file.config(font=("Helvetica", 12))
        self.lbl_file.pack(side="top")
        self.txt_file = tk.Entry(self, width=50)
        self.txt_file.pack(side="top", padx=5, pady=5)

        self.btn_cargar = tk.Button(self, text="Cargar", width=50, command=self.cargar_base_json)
        self.btn_cargar.pack(side="top", padx=5, pady=5)

        self.btn_guardar = tk.Button(self, text="Guardar", width=50, command=self.guardar_base_json)
        self.btn_guardar.pack(side="top", padx=5, pady=5)

        self.quit = tk.Button(self, text="Cerrar", fg="red", width=50, command=self.master.destroy)
        self.quit.pack(side="bottom", padx=5, pady=5)

    def guardar_base_json(self):
        acciones.guardar(self.txt_file.get())

    def cargar_base_json(self):
        acciones.cargar(self.txt_file.get())
        self.master.destroy()
