<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-KK94CHFLLe+nY2dmCWGMq91rCGa5gtU4mk92HdvYe+M/SXH301p5ILy+dN9+nJOZ" crossorigin="anonymous">
    <title>Sistema de Punto de Venta</title>
</head>
<body class="container">
    <div class="container text-center mt-5">
        <div class="row">
            <div class="col">
            <img alt="" src="../../assets/tpv.png" width="70"/>
            </div>
            <div class="col">
                <h1>Sistema Terminal de Punto de Venta</h1>
                <h2>Modulo Adgregar Proveedores</h2>
            </div>
            <div class="col">
            <a href="#"><img alt="informacion" src="../../assets/informacion.png" width="70"/></a>
            <a href="#"><img alt="cerrar sesion" src="../../assets/verificar.png" width="70"/></a>
            </div>
        </div>
        <div class="row text-bg-primary p-1 m-1">
            <div class="col">
            <p>Nombre Usuario: admin</p>
            </div>
            <div class="col">
            <p>Fecha / Hora de Ingreso: 17/04/2023 03:27:12</p>
            </div>
        </div>
        <form method="post">
            <h2>Formulario de Registro de Proveedores</h2>
            <div class="mt-4">
                <div class="row">
                    <div class="col-2">
                    </div>
                    <div class="col-5">
                        <input type="text" class="form-control" value="" name="name" placeholder="Introduce el nomble completo del proveedor"/>
                    </div>
                    <div class="col-3">
                        <input type="submit" class="btn btn-primary" name="Agrega" value="Agregar"/>
                        <a href="../proveedores.php" class="btn btn-danger">Cerrar</a>
                    </div>
                    <div class="col-2">                    </div>
                </div>
            </div>
        </form> 
        <?php
            if($_POST){
                $server = "localhost";
                $user = "root";
                $pass = "";
                $bd = "tpv";

                $conn = mysqli_connect($server, $user, $pass, $bd);
                $nombreCompleto = $_POST['name'];

                $busca = "Select * from proveedor where nombreCompleto = $nombreCompleto";
                $ejecutar1 = mysqli_query($conn, $busca);
                
                if (mysqli_num_rows($ejecutar1) > 0) {
                    // output data of each row
                    while($row = mysqli_fetch_assoc($ejecutar1)) {
                      echo "id: ".$row["idproveedor"]." - Name: ".$row["nombreCompleto"]."<br>";
                    }
                  } else {
                    echo "0 results";
                  }
            }

        ?>       
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/js/bootstrap.bundle.min.js" integrity="sha384-ENjdO4Dr2bkBIFxQpeoTz1HIcje39Wm4jDKdf19U8gI4ddQ3GYNS7NTKfAdVQSZe" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.7/dist/umd/popper.min.js" integrity="sha384-zYPOMqeu1DAVkHiLqWBUTcbYfZ8osu1Nd6Z89ify25QV9guujx43ITvfi12/QExE" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/js/bootstrap.min.js" integrity="sha384-Y4oOpwW3duJdCWv5ly8SCFYWqFDsfob/3GkgExXKV4idmbt98QcxXYs9UoXAB7BZ" crossorigin="anonymous"></script>
</body>
</html>