<?php

session_start();
if($_SESSION['rol'] !=1 and $_SESSION['rol'] !=2)
    {
        header("location: ./");
    }

    include "../conexion.php";

    if(!empty($_POST))
    {
        $alert='';
        if(empty($_POST['proveedor']) || empty($_POST['contacto']) || empty($_POST['telefono']) || empty($_POST['direccion'])) 
        {
            $alert='<p class="msg_error">Todos los campos son obligatorios.</p>';
        }else{

            $idProveedor = $_POST['id'];
            $proveedor = $_POST['proveedor'];
            $contacto = $_POST['contacto'];
            $telefono = $_POST['telefono'];
            $direccion = $_POST['direccion'];

            $sql_update = mysqli_query($conection, "UPDATE proveedor
                                                            SET proveedor = '$proveedor', contacto = '$contacto', telefono = '$telefono', direccion = '$direccion'
                                                            WHERE codproveedor= $idProveedor");
            
            if($sql_update){
                    $alert='<p class="msg_save">Proveedor actualizado correctamente.</p>';
                }else{
                    $alert='<p class="msg_error">Error al actualizar el Proveedor.</p>';
            }
    }
}

//Mostrar datos
    if(empty($_REQUEST['id']))
    {
        header('Location: lista_proveedor.php');
        mysqli_close($conection);
    }
    $idproveedor = $_REQUEST['id'];

    $sql = mysqli_query($conection,"SELECT * FROM proveedor WHERE codproveedor= $idproveedor and estatus = 1");

    mysqli_close($conection);
    $result_sql = mysqli_num_rows($sql);

    if($result_sql == 0){
            header('Location: lista_proveedor.php');
    }else{
        while($data = mysqli_fetch_array($sql)){

            $idproveedor = $data['codproveedor'];
            $provedor = $data['proveedor'];
            $contacto = $data['contacto'];
            $telefono = $data['telefono'];
            $direccion = $data['direccion'];
        }
    }
?>

<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<?php include "includes/scripts.php"; ?>
	<title>Actualizar Proveedor</title>
</head>
<body>
<?php include "includes/header.php"; ?>
	<section id="container">

		<div class="form_register">
        <h1><i class="fas fa-industry"></i> Actualizar Proveedor</h1>
        <hr> 
        <div class="alert"><?php echo isset($alert) ? $alert : ''; ?></div>

        <form action="" method="post">
            <input type="hidden" name="id" value="<?php echo $idproveedor; ?>">
            <label for="proveedor">Proveedor</label>
            <input type="text" name="proveedor" id="proveedor" placeholder="Nombre del Proveedor" value="<?php echo $provedor ?>">
            <label for="contacto">Contacto</label>
            <input type="text" name="contacto" id="contacto" placeholder="Nombre Completo del Contacto" value="<?php echo $contacto ?>">
            <label for="telefono">Teléfono</label>
            <input type="number" name="telefono" id="telefono" placeholder="Teléfono" value="<?php echo $telefono ?>">
            <label for="direccion">Dirección</label>
            <input type="text" name="direccion" id="direccion" placeholder="Dirección Completa" value="<?php echo $direccion ?>">
        
            <input type="submit" value="Actualizar Proveedor" class="btn_save">
            
        </form>
</div>
    	</section>

	<?php include "includes/footer.php"; ?>
</body>
</html>