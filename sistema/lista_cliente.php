<?php
    
    session_start();
    include "../conexion.php";
?>

<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<?php include "includes/scripts.php"; ?>
	<title>Lista de Clientes</title>
</head>
<body>
<?php include "includes/header.php"; ?>
	<section id="container">
		<h1><i class="fas fa-users"></i> Lista de Clientes</h1>
        <a href="registro_cliente.php" class="btn_new"><i class="fas fa-plus-circle"></i> Registrar Cliente</a>
        
        <form action="buscar_cliente.php" method="get" class="form_search">
            <input type="text" name="busqueda" id="busqueda" placeholder="Buscar">
            <button type="submit" class="btn_view"><i class="fas fa-search"></i></button>
        </form>
        <table>
            <tr>
                <th>ID</th>
                <th>Nuit</th>
                <th>Nome</th>
                <th>Email</th>
                <th>Telefono</th>
                <th>Endereço</th>
                <th>Ações</th>
            </tr>
        <?php
        //Paginador
        $sql_registe = mysqli_query($conection, "SELECT COUNT(*) as total_registro FROM cliente WHERE estatus = 1 ");
        $result_register = mysqli_fetch_array($sql_registe);
        $total_registro = $result_register['total_registro'];
 
        $por_pagina = 10;

        if(empty($_GET['pagina']))
        {
            $pagina =1;
        }else{
            $pagina = $_GET['pagina'];
        }

        $desde = ($pagina-1) * $por_pagina;
        $total_paginas = ceil($total_registro / $por_pagina);

            $query = mysqli_query($conection, "SELECT*FROM cliente  
                                                WHERE estatus = 1 
                                                ORDER BY idcliente ASC LIMIT $desde,$por_pagina");
            
            mysqli_close($conection);

            $result = mysqli_num_rows($query);
            if($result > 0){

                    while($data = mysqli_fetch_array($query)) {
                       ?>
                <tr>
                <td><?php echo $data["idcliente"] ?></td>
                <td><?php echo $data["rfc"] ?></td>
                <td><?php echo $data["nombre"] ?></td>
                <td><?php echo $data["correo"] ?></td>
                <td><?php echo $data["telefono"] ?></td>
                <td><?php echo $data["direccion"] ?></td>
                <td>
                    <a class="link_edit" href="editar_cliente.php?id=<?php echo $data["idcliente"]; ?>"><i class="fas fa-edit"></i> Editar</a>
                    <?php if($_SESSION['rol'] == 1 || $_SESSION['rol'] == 2){ ?>
                    |
                    
                        <a class="link_delete" href="eliminar_confirmar_cliente.php?id=<?php echo $data["idcliente"];?>"><i class="fas fa-trash-alt"></i> Eliminar</a>
                    <?php } ?>
                </td>
            </tr>
            <?php
            }

        }
        ?>
        </table>
        <div class="paginador"> 
            <ul>
                <?php
                    if($pagina != 1)
                    {
                ?>
                 <li><a href="?pagina=<?php echo 1; ?>"><i class="fas fa-angle-double-left"></i></a></li>
                <li><a href="?pagina=<?php echo $pagina-1; ?>"><i class="fas fa-angle-left"></i></a></li>
            <?php
                    }
                for ($i=1; $i <= $total_paginas; $i++){
                    if($i == $pagina)
                    {
                        echo '<li class="pageSelected">'.$i.'</li>';
                    }else{
                        echo '<li><a href="?pagina='.$i.'">'.$i.'</a></li>';
                    }
                    
                }
                if($pagina != $total_paginas)
                {
                ?>
                <li><a href="?pagina=<?php echo $pagina + 1; ?>"><i class="fas fa-angle-right"></i></a></li>
                <li><a href="?pagina=<?php echo $total_paginas; ?>"><i class="fas fa-angle-double-right"></i></a></li>
                <?php } ?>
    </div>
	</section>
	<?php include "includes/footer.php"; ?>
</body>
</html>