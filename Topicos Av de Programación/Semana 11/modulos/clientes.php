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
            <img alt="" src="../assets/tpv.png" width="70"/>
            </div>
            <div class="col">
                <h1>Sistema Terminal de Punto de Venta</h1>
                <h2>Modulo Clientes</h2>
            </div>
            <div class="col">
            <a href="#"><img alt="informacion" src="../assets/informacion.png" width="70"/></a>
            <a href="#"><img alt="cerrar sesion" src="../assets/verificar.png" width="70"/></a>
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
        <div class="row mt-5">
            <div class="col">
                <a href="./acciones/addproveedor.php"><img alt="" src="../assets/adduser.png" width="100"/></a>
                <p>Agregar Cliente</p>
            </div>
            <div class="col">
                <a href="../dashboard.php"><img alt="" src="../assets/cerrar.png" width="100"/></a>
                <p>Cerrar</p>
            </div>
        </div>
        <div class="row mt-5">
            <h3>Lista de Clientes</h3>
        </div>
        <div class="row mt-5">
            <div class="col">
                <form>
                <p>Buscar por:
                <select name="filtro" class="form-select-sm">
                    <option value="1">Id</option>
                    <option value="1">Nombre</option>
                </select>
                <input type="text" class="form-control-sm" name="valor"/>
                <input type="submit" class="btn btn-primary" value="Buscar" name="boton"/>
                <input type="submit" class="btn btn-secondary" value="Limpiar" name="boton"/>
                </p>
                </form>
            </div>
        </div>
        <!--Data Table-->
        <div class="row mt-5">
            <div class="col">
                <!--LLamada a base de datos-->
                <table class="table">
                    <thead>
                        <tr>
                            <th>Id</th>
                            <th>Nombre</th>
                            <th></th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>1</td>
                            <td>Juan Perez</td>
                            <td><a href="#" class="btn btn-success">Editar</a></td>
                            <td><a href="#" class="btn btn-danger">Borrar</a></td>
                        </tr>
                        <tr>
                            <td>2</td>
                            <td>Maria Lopez</td>
                            <td><a href="#" class="btn btn-success">Editar</a></td>
                            <td><a href="#" class="btn btn-danger">Borrar</a></td>
                        </tr>
                        <tr>
                            <td>3</td>
                            <td>Felipe Morales</td>
                            <td><a href="#" class="btn btn-success">Editar</a></td>
                            <td><a href="#" class="btn btn-danger">Borrar</a></td>
                        </tr>
                        <tr>
                            <td>4</td>
                            <td>Rocio Sanchez</td>
                            <td><a href="#" class="btn btn-success">Editar</a></td>
                            <td><a href="#" class="btn btn-danger">Borrar</a></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/js/bootstrap.bundle.min.js" integrity="sha384-ENjdO4Dr2bkBIFxQpeoTz1HIcje39Wm4jDKdf19U8gI4ddQ3GYNS7NTKfAdVQSZe" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.7/dist/umd/popper.min.js" integrity="sha384-zYPOMqeu1DAVkHiLqWBUTcbYfZ8osu1Nd6Z89ify25QV9guujx43ITvfi12/QExE" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/js/bootstrap.min.js" integrity="sha384-Y4oOpwW3duJdCWv5ly8SCFYWqFDsfob/3GkgExXKV4idmbt98QcxXYs9UoXAB7BZ" crossorigin="anonymous"></script>
</body>
</html>