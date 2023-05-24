import tkinter as tk
from tkinter import ttk
import acciones


class InsertarBase(tk.Frame):
    def __init__(self):
        root = tk.Toplevel()
        super().__init__(root)
        root.geometry('380x450')
        root.title('Insertar entrada')
        root.resizable(width=False, height=False)
        self.master = root
        self.pack()

        self.lbl_base = tk.Label(self, text="Insertar una entrada")
        self.lbl_base.pack(side="top")
        self.lbl_base.config(font=("Helvetica", 24))

        self.entradas = ttk.Treeview(self)
        self.entradas.pack(side="top")
        self.entradas.tag_bind("tag_select", "<<TreeviewSelect>>", self.item_selected)
        self.fill_base_tree_view()

        self.lbl_entry = tk.Label(self, text="Nombre de la entrada:")
        self.lbl_entry.pack(side="top")
        self.lbl_entry.config(font=("Helvetica", 12))
        self.txt_entry = tk.Entry(self, width=50)
        self.txt_entry.pack(side="top", padx=5, pady=5)

        self.lbl_prop = tk.Label(self, text="Propiedad:")
        self.lbl_prop.pack(side="top")
        self.lbl_prop.config(font=("Helvetica", 12))
        self.txt_prop = tk.Entry(self, width=50)
        self.txt_prop.pack(side="top", padx=5, pady=5)

        self.btn_insertar = tk.Button(self, text="Insertar", width=50, command=self.add_propiedad)
        self.btn_insertar.pack(side="top", padx=5, pady=5)

        self.quit = tk.Button(self, text="Salir", fg="red", width=50, command=self.master.destroy)
        self.quit.pack(side="bottom", padx=5, pady=5)

    def fill_base_tree_view(self):
        self.entradas.delete(*self.entradas.get_children())
        base = self.entradas.insert("", tk.END, text="Base")
        base_entries = acciones.get_base_entries()
        for entry in base_entries:
            nombre = self.entradas.insert(base, tk.END, text=entry.name, tags=("tag_select",))
            for prop in entry.properties:
                self.entradas.insert(nombre, tk.END, text=prop.name)

    def add_propiedad(self):
        entrada = self.txt_entry.get()
        propiedad = self.txt_prop.get()

        acciones.insertar(entrada, propiedad)
        self.txt_prop.delete(0, "end")
        self.fill_base_tree_view()

    def item_selected(self, event):
        id = event.widget.focus()
        text = self.entradas.item(id)["text"]
        self.txt_entry.delete(0, tk.END)
        self.txt_entry.insert(0, text)
