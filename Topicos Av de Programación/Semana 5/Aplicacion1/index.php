<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-GLhlTQ8iRABdZLl6O3oVMWSktQOp6b7In1Zl3/Jr59b6EGGoI1aFkw7cmDA6j6gD" crossorigin="anonymous">
    <title>Primera Aplicacion PHP</title>
</head>
<body>
    <div class="container">
    <h1>Primera Aplicacion PHP</h1>
    <?php
        //echo permite dar salidas a pantalla
        echo "Saludos";
        echo "<br>";
        //Declara 2 Variables
        $num = 10;
        $resultado = $num + 10;
        echo "Resultado de la variable num es: ".$num;
        echo "<br>";
        echo "Resultado de la variable resultaado es: ".$resultado;

        //Segundo Ejemplo
        echo "<br>";
        echo "Saludo 2 Texto simple";
        echo "<p>Este es un parrafo desde PHP.</p>";
        echo "Texto Concatenado con Variable ".$num." 
        y Varible concatenada con texto <strong>
        Y yo soy una cadena con html.</strong>";
        ?>
    </div>

    <div class="container">
        <h1>Segundo Ejemplo de PhP</h1>
        <?php
            //Declaración de un arreglo
            $autos = ["Ford", "Kia", "BMW", "Mercedes Benz", "Nissan"];
            echo "<ol>";
            echo "<li>".$autos[0]."</li>";
            echo "<li>".$autos[1]."</li>";
            echo "<li>".$autos[2]."</li>";
            echo "<li>".$autos[3]."</li>";
            echo "<li>".$autos[4]."</li>";
            echo "</ol>";
        ?>
    </div>

    <div class="container">
        <h1>Tercer Ejemplo de PhP</h1>
        <?php
            //Declaración de un Objeto
            //Primer paso declarar la clase
            class miAuto {
                public $nombre;
                public $año;
                public $tipo;
            };
             //Segundo paso declara el objeto
             $miAuto =  new miAuto();

             //Tercer paso asignar valores
             $miAuto->nombre = "Ford";
             $miAuto->año = 2023;
             $miAuto->tipo = "Sedan";

             //Cuarto paso mostrar el resultado
             echo "<p>Hola me llamo arturo y tengo un auto marca
              ".$miAuto->nombre." 
             Modelo ".$miAuto->año." Tipo ".$miAuto->tipo."</p>";
        ?>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js" integrity="sha384-w76AqPfDkMBDXo30jS1Sgez6pr3x5MlQ1ZAGC+nuZB+EYdgRZgiwxhTBTkF7CXvN" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.6/dist/umd/popper.min.js" integrity="sha384-oBqDVmMz9ATKxIep9tiCxS/Z9fNfEXiDAYTujMAeBAsjFuCZSmKbSSUnQlmh/jp3" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.min.js" integrity="sha384-mQ93GR66B00ZXjt0YO5KlohRA5SY2XofN4zfuZxLkoj1gXtW8ANNCe9d5Y3eG5eD" crossorigin="anonymous"></script>
  </body>
</body>
</html>