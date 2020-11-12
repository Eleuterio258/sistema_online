-- phpMyAdmin SQL Dump
-- version 5.0.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3307
-- Tiempo de generación: 11-05-2020 a las 21:24:04
-- Versión del servidor: 10.4.11-MariaDB
-- Versión de PHP: 7.4.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `facturacion`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_precio_producto` (`n_cantidad` INT, `n_precio` DECIMAL(10,2), `codigo` INT)  BEGIN
    	DECLARE nueva_existencia int;
        DECLARE nuevo_total  decimal(10,2);
        DECLARE nuevo_precio decimal(10,2);
        
        DECLARE cant_actual int;
        DECLARE pre_actual decimal(10,2);
        
        DECLARE actual_existencia int;
        DECLARE actual_precio decimal(10,2);
                
        SELECT precio,existencia INTO actual_precio,actual_existencia FROM producto WHERE codproducto = codigo;
        SET nueva_existencia = actual_existencia + n_cantidad;
        SET nuevo_total = (actual_existencia * actual_precio) + (n_cantidad * n_precio);
        SET nuevo_precio = nuevo_total / nueva_existencia;
        
        UPDATE producto SET existencia = nueva_existencia, precio = nuevo_precio WHERE codproducto = codigo;
        
        SELECT nueva_existencia,nuevo_precio;
        
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_detalle_temp` (IN `codigo` INT, IN `cantidad` INT, IN `token_user` VARCHAR(50))  BEGIN
    
    	DECLARE precio_actual decimal(10,2);
        SELECT precio INTO precio_actual FROM producto WHERE codproducto = codigo;
        
        INSERT INTO detalle_temp(token_user,codproducto,cantidad,precio_venta) VALUES(token_user,codigo,cantidad,precio_actual);
        
        SELECT tmp.correlativo, tmp.codproducto,p.descripcion,tmp.cantidad,tmp.precio_venta FROM detalle_temp tmp
        INNER JOIN producto p
        ON tmp.codproducto = p.codproducto
        WHERE tmp.token_user = token_user;
        
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `anular_factura` (`no_factura` INT)  BEGIN
        	DECLARE existe_factura int;
            DECLARE registros int;
            DECLARE a int;
            
            DECLARE cod_producto int;
            DECLARE cant_producto int;
            DECLARE existencia_actual int;
            DECLARE nueva_existencia int;
            
            SET existe_factura = (SELECT COUNT(*) FROM factura WHERE nofactura = no_factura and estatus = 1);
            
            IF existe_factura > 0 THEN
            	CREATE TEMPORARY TABLE tbl_tmp (
                id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                cod_prod BIGINT,
                cant_prod int);
                
                SET a = 1;
                
                SET registros = (SELECT COUNT(*) FROM detallefactura WHERE nofactura = no_factura);
                
                IF registros > 0 THEN
                	
                	INSERT INTO tbl_tmp(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detallefactura WHERE nofactura = no_factura;
                    
                    WHILE a <= registros DO
                    	SELECT cod_prod,cant_prod INTO cod_producto,cant_producto FROM tbl_tmp WHERE id = a;
                        SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = cod_producto;
                        SET nueva_existencia = existencia_actual + cant_producto;
                        UPDATE producto SET existencia = nueva_existencia WHERE codproducto = cod_producto;
                        
                        SET a=a+1;                        
                    END WHILE;
                    
                    UPDATE factura SET estatus = 2 WHERE nofactura = no_factura;
                    DROP TABLE tbl_tmp;
                    SELECT * FROM factura WHERE nofactura = no_factura;
                
                END IF; 
            
            ELSE
            	SELECT 0 factura;
            END IF;
            
            
            
         END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `dataDashboard` ()  BEGIN
    	
        DECLARE usuarios int;
        DECLARE clientes int;
        DECLARE proveedores int;
        DECLARE productos int;
        DECLARE ventas int;
        
        SELECT COUNT(*) INTO usuarios FROM usuario WHERE estatus != 10;
        SELECT COUNT(*) INTO clientes FROM cliente WHERE estatus != 10;
        SELECT COUNT(*) INTO proveedores FROM proveedor WHERE estatus != 10;
        SELECT COUNT(*) INTO productos FROM producto WHERE estatus != 10;
        SELECT COUNT(*) INTO ventas FROM factura WHERE fecha > CURDATE() AND estatus != 10;
        
        SELECT usuarios,clientes,proveedores,productos,ventas;
        
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `del_detalle_temp` (IN `id_detalle` INT, IN `token` VARCHAR(50))  BEGIN
    	DELETE FROM detalle_temp WHERE correlativo = id_detalle;
        
        SELECT tmp.correlativo, tmp.codproducto, p.descripcion, tmp.cantidad, tmp.precio_venta FROM detalle_temp tmp
        INNER JOIN producto p
        ON tmp.codproducto = p.codproducto
        WHERE tmp.token_user = token;
      END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procesar_venta` (IN `cod_usuario` INT, IN `cod_cliente` INT, IN `token` VARCHAR(50))  BEGIN
    	DECLARE factura INT;
        
        DECLARE registros INT;
        DECLARE total DECIMAL(10,2);
        
        DECLARE nueva_existencia int;
        DECLARE existencia_actual int;
        
        DECLARE tmp_cod_producto int;
        DECLARE tmp_cant_producto int;
        DECLARE a INT;
        SET a = 1;
        
        CREATE TEMPORARY TABLE tbl_tmp_tokenuser (
            id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            cod_prod BIGINT,
            cant_prod int);
            
        SET registros = (SELECT COUNT(*) FROM detalle_temp WHERE token_user = token);
		
        IF registros > 0 THEN 
        	INSERT INTO tbl_tmp_tokenuser(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detalle_temp WHERE token_user = token;
            
            INSERT INTO factura(usuario,codcliente) VALUES(cod_usuario,cod_cliente);
            SET factura = LAST_INSERT_ID();
            
            INSERT INTO detallefactura(nofactura,codproducto,cantidad,precio_venta) SELECT (factura) as nofactura, codproducto, cantidad, precio_venta FROM detalle_temp
            WHERE token_user = token;
            
            WHILE a <= registros DO
            	SELECT cod_prod,cant_prod INTO tmp_cod_producto, tmp_cant_producto FROM tbl_tmp_tokenuser WHERE id = a;
                SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = tmp_cod_producto;
                
                SET nueva_existencia = existencia_actual - tmp_cant_producto;
                UPDATE producto SET existencia = nueva_existencia WHERE codproducto = tmp_cod_producto;
                
                SET a=a+1;
                
            END WHILE;
            
            SET total = (SELECT SUM(cantidad * precio_venta) FROM detalle_temp WHERE token_user = token);
            UPDATE factura SET totalfactura = total WHERE nofactura = factura;
            DELETE FROM detalle_temp WHERE token_user = token;
            TRUNCATE TABLE tbl_tmp_tokenuser;
            SELECT * FROM factura WHERE nofactura = factura;        
        ELSE
        SELECT 0;
        END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `idcliente` int(11) NOT NULL,
  `rfc` varchar(13) DEFAULT NULL,
  `nombre` varchar(80) DEFAULT NULL,
  `telefono` bigint(10) DEFAULT NULL,
  `correo` varchar(100) NOT NULL,
  `direccion` text DEFAULT NULL,
  `dateadd` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`idcliente`, `rfc`, `nombre`, `telefono`, `correo`, `direccion`, `dateadd`, `usuario_id`, `estatus`) VALUES
(1, '0', 'CLIENTE', 0, '', 'Monterrey N.L', '2020-05-02 20:37:59', 1, 1),
(2, 'DAVA991228CT5', 'Daniela Valladarez', 8475859685, 'danielava@gmail.com', 'Av. Nogalar 104', '2020-04-20 12:35:01', 1, 1),
(3, 'RCMA980528ET9', 'Arely Ramirez', 8185826985, 'arelyr@gmail.com', 'San Miguel', '2020-04-20 12:36:54', 1, 1),
(10, 'BAPE991227BT9', 'Eduardo Perez', 8182052682, '', 'Res. Santa Fé', '2020-04-20 12:32:43', 1, 1),
(33, 'CACE971227CT8', 'Ernesto', 8285748596, '', 'Residencial Los PInos', '2020-04-30 21:25:00', 1, 1),
(34, 'PBRA671107FRE', 'Antonio Perez', 8475869584, '', 'Av. Casa Blanca ', '2020-04-30 21:37:41', 1, 1),
(35, 'BGRE987458RT8', 'Rodrigo', 8574859685, '', 'Av. Encino 105', '2020-04-30 21:40:00', 1, 1),
(37, 'TERMDO875412', 'Andrea', 8475859685, '', 'equis', '2020-05-08 12:11:17', 1, 1),
(38, 'ñndñnfñdn', 'sñdnsls', 845784858, '', 'ñdndsjfkjsd', '2020-05-08 12:19:46', 1, 1),
(39, 'njfnsodjfpjdo', 'prueba2', 8182748596, '', 'ñsdflkjdsñklfjsfjdl', '2020-05-08 12:27:41', 1, 1),
(40, 'idhspohsoñjsd', 'slbdbajdkkjsc', 818205748, '', 'nxñkldmnñlfm-dmf', '2020-05-08 12:28:53', 1, 1),
(41, 'EDPTFNRD89', 'TERNO', 8475869, '', 'JKNFÑÑFDJDFFFD', '2020-05-08 12:31:15', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `configuracion`
--

CREATE TABLE `configuracion` (
  `id` bigint(20) NOT NULL,
  `rfc` varchar(13) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `razon_social` varchar(100) NOT NULL,
  `telefono` bigint(20) NOT NULL,
  `email` varchar(100) NOT NULL,
  `direccion` text NOT NULL,
  `iva` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `configuracion`
--

INSERT INTO `configuracion` (`id`, `rfc`, `nombre`, `razon_social`, `telefono`, `email`, `direccion`, `iva`) VALUES
(1, 'FELOFJELFO', 'ELECTRONIC SHOP', 'electronica y mas', 8285748596, 'electronicshop@gmail.com', 'Calzada La paz Monterrey', '16.00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detallefactura`
--

CREATE TABLE `detallefactura` (
  `correlativo` bigint(11) NOT NULL,
  `nofactura` bigint(11) DEFAULT NULL,
  `codproducto` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `precio_venta` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `detallefactura`
--

INSERT INTO `detallefactura` (`correlativo`, `nofactura`, `codproducto`, `cantidad`, `precio_venta`) VALUES
(40, 14, 14, 1, '1500.00'),
(41, 15, 11, 1, '800.00'),
(42, 15, 12, 1, '423.00'),
(43, 15, 13, 1, '550.00'),
(44, 15, 14, 2, '1500.00'),
(48, 16, 11, 1, '800.00'),
(49, 16, 12, 1, '423.00'),
(52, 18, 11, 1, '800.00'),
(53, 18, 12, 1, '423.00'),
(54, 19, 11, 1, '800.00'),
(55, 19, 12, 1, '423.00'),
(56, 19, 13, 4, '550.00'),
(57, 20, 12, 1, '423.00'),
(58, 20, 13, 1, '550.00'),
(60, 21, 12, 1, '423.00'),
(61, 22, 12, 1, '423.00'),
(62, 23, 12, 1, '423.00'),
(63, 24, 13, 1, '550.00'),
(64, 25, 12, 2, '423.00'),
(65, 25, 15, 1, '2000.00'),
(67, 26, 16, 1, '3700.00'),
(68, 27, 18, 1, '900.00'),
(69, 27, 19, 1, '1300.00'),
(71, 28, 18, 1, '900.00'),
(72, 28, 19, 1, '1300.00'),
(73, 28, 16, 1, '3700.00'),
(74, 29, 16, 1, '3700.00'),
(75, 29, 18, 1, '900.00'),
(77, 30, 11, 1, '800.00'),
(78, 31, 11, 1, '800.00'),
(79, 31, 12, 10, '423.00'),
(81, 32, 11, 1, '800.00'),
(82, 32, 12, 2, '423.00'),
(84, 33, 16, 2, '3700.00'),
(85, 33, 18, 1, '900.00'),
(86, 34, 11, 2, '800.00'),
(87, 35, 12, 2, '423.00'),
(88, 36, 12, 1, '423.00'),
(89, 36, 13, 1, '550.00'),
(90, 36, 14, 2, '1500.00'),
(91, 37, 13, 30, '550.00'),
(92, 37, 14, 10, '1500.00'),
(93, 38, 12, 1, '423.00'),
(94, 39, 11, 1, '800.00'),
(95, 39, 12, 1, '423.00'),
(96, 39, 13, 1, '550.00'),
(97, 40, 12, 1, '423.00'),
(98, 41, 12, 1, '423.00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_temp`
--

CREATE TABLE `detalle_temp` (
  `correlativo` int(11) NOT NULL,
  `token_user` varchar(50) NOT NULL,
  `codproducto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_venta` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `entradas`
--

CREATE TABLE `entradas` (
  `correlativo` int(11) NOT NULL,
  `codproducto` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `cantidad` int(11) NOT NULL,
  `precio` decimal(10,2) NOT NULL,
  `usuario_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `entradas`
--

INSERT INTO `entradas` (`correlativo`, `codproducto`, `fecha`, `cantidad`, `precio`, `usuario_id`) VALUES
(1, 11, '2020-04-22 11:44:48', 25, '150.00', 1),
(12, 12, '2020-04-22 11:47:34', 30, '450.00', 1),
(13, 13, '2020-04-22 11:48:08', 15, '550.00', 1),
(14, 14, '2020-04-22 11:49:09', 50, '1500.00', 1),
(15, 15, '2020-04-22 11:50:02', 15, '2000.00', 1),
(16, 16, '2020-04-22 11:53:47', 70, '3700.00', 1),
(17, 17, '2020-04-26 22:49:24', 15, '1500.00', 1),
(18, 12, '2020-04-27 00:37:47', 20, '550.00', 1),
(19, 12, '2020-04-27 00:41:33', 10, '100.00', 1),
(20, 11, '2020-04-27 11:02:44', 100, '80.00', 1),
(21, 11, '2020-04-27 11:03:33', 100, '80.00', 1),
(22, 12, '2020-04-27 11:15:35', 20, '450.00', 1),
(23, 12, '2020-04-27 11:19:07', 20, '400.00', 1),
(24, 12, '2020-04-27 11:26:25', 20, '400.00', 1),
(25, 14, '2020-04-27 11:27:55', 10, '1500.00', 1),
(26, 14, '2020-04-27 11:29:22', 10, '1500.00', 1),
(27, 14, '2020-04-27 11:42:46', 10, '1500.00', 1),
(28, 17, '2020-04-27 11:43:26', 10, '1550.00', 1),
(29, 17, '2020-04-27 11:47:37', 10, '1530.00', 1),
(30, 11, '2020-04-27 12:01:42', 10, '150.00', 1),
(31, 11, '2020-04-27 12:10:27', 1, '120.00', 1),
(32, 12, '2020-04-27 12:11:10', 10, '450.00', 1),
(33, 13, '2020-04-27 12:12:37', 10, '550.00', 1),
(34, 11, '2020-04-27 12:33:27', 100, '150.00', 1),
(35, 18, '2020-04-27 18:10:33', 10, '899.00', 1),
(36, 19, '2020-04-27 20:28:50', 10, '1300.00', 1),
(37, 11, '2020-05-01 12:35:37', 10, '800.00', 1),
(38, 11, '2020-05-01 12:35:53', 10, '800.00', 1),
(39, 11, '2020-05-01 12:36:07', 10, '800.00', 1),
(40, 11, '2020-05-01 12:36:50', 10, '800.00', 1),
(41, 18, '2020-05-02 21:20:38', 100, '900.00', 1),
(42, 19, '2020-05-02 21:20:53', 100, '1300.00', 1),
(43, 13, '2020-05-03 13:59:31', 100, '550.00', 1),
(44, 15, '2020-05-07 11:37:09', 100, '2000.00', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `factura`
--

CREATE TABLE `factura` (
  `nofactura` bigint(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario` int(11) DEFAULT NULL,
  `codcliente` int(11) DEFAULT NULL,
  `totalfactura` decimal(10,2) DEFAULT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `factura`
--

INSERT INTO `factura` (`nofactura`, `fecha`, `usuario`, `codcliente`, `totalfactura`, `estatus`) VALUES
(13, '2020-05-02 18:29:14', 1, 3, '1450.00', 1),
(14, '2020-05-02 18:54:44', 1, 33, '1500.00', 1),
(15, '2020-05-02 21:07:59', 1, 10, '4773.00', 1),
(16, '2020-05-02 21:09:41', 1, 10, '1223.00', 1),
(18, '2020-05-02 21:17:51', 1, 1, '1223.00', 1),
(19, '2020-05-03 12:54:44', 1, 10, '3423.00', 1),
(20, '2020-05-03 14:08:04', 1, 1, '973.00', 1),
(21, '2020-05-03 14:09:36', 1, 1, '423.00', 1),
(22, '2020-05-03 14:11:00', 1, 1, '423.00', 1),
(23, '2020-05-03 14:13:05', 1, 1, '423.00', 1),
(24, '2020-05-03 14:17:33', 1, 1, '550.00', 1),
(25, '2020-05-03 14:55:27', 1, 2, '2846.00', 2),
(26, '2020-05-03 14:59:45', 1, 2, '3700.00', 1),
(27, '2020-05-03 15:00:27', 1, 2, '2200.00', 1),
(28, '2020-05-03 15:02:30', 1, 2, '5900.00', 1),
(29, '2020-05-03 15:13:00', 1, 2, '4600.00', 1),
(30, '2020-05-03 15:14:46', 1, 1, '800.00', 2),
(31, '2020-05-03 15:16:15', 1, 10, '5030.00', 1),
(32, '2020-05-03 19:29:00', 1, 1, '1646.00', 2),
(33, '2020-05-03 21:26:44', 1, 1, '8300.00', 2),
(34, '2020-05-04 12:35:45', 1, 33, '1600.00', 1),
(35, '2020-05-04 17:10:15', 4, 2, '846.00', 2),
(36, '2020-05-07 11:38:52', 1, 33, '3973.00', 1),
(37, '2020-05-07 20:15:18', 1, 3, '31500.00', 1),
(38, '2020-05-08 12:06:17', 1, 1, '423.00', 1),
(39, '2020-05-08 12:58:41', 1, 1, '1773.00', 1),
(40, '2020-05-08 13:03:16', 1, 1, '423.00', 1),
(41, '2020-05-08 13:41:18', 1, 2, '423.00', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `codproducto` int(11) NOT NULL,
  `descripcion` varchar(100) DEFAULT NULL,
  `proveedor` int(11) DEFAULT NULL,
  `precio` decimal(10,2) DEFAULT NULL,
  `existencia` int(11) DEFAULT NULL,
  `date_add` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1,
  `foto` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`codproducto`, `descripcion`, `proveedor`, `precio`, `existencia`, `date_add`, `usuario_id`, `estatus`, `foto`) VALUES
(11, 'Chromecast', 20, '820.00', 470, '2020-04-22 11:44:48', 1, 1, 'img_3a3c17d892935250556f24614688030a.jpg'),
(12, 'Cargador Laptop Acer', 17, '423.00', 116, '2020-04-22 11:47:34', 1, 1, 'img_e183808ba89886bbf7f6bc3898198552.jpg'),
(13, 'Cargador Laptop hp', 15, '550.00', 71, '2020-04-22 11:48:08', 1, 1, 'img_d5b5ac3d59d26dd0b0e50e2c8e008342.jpg'),
(14, 'Monitor  Dell 19\"', 2, '1500.00', 65, '2020-04-22 11:49:09', 1, 1, 'img_53aa5b6425ef483b7a4f874a7c36ba5f.jpg'),
(15, 'Monitor hp 19\"', 15, '2000.00', 109, '2020-04-22 11:50:02', 1, 1, 'img_43175d90073baa2d27c3b32e7c57dbe8.jpg'),
(16, 'Procesador AMD', 18, '3700.00', 71, '2020-04-22 11:53:47', 1, 1, 'img_90c252567fd3cd8a517ea0b72463e631.jpg'),
(17, 'luna', 2, '1500.00', 35, '2020-04-26 22:49:24', 1, 0, 'img_producto.png'),
(18, 'Teclado', 19, '900.00', 106, '2020-04-27 18:10:33', 1, 1, 'img_1b6f09bae2382f812627fa75429628a6.jpg'),
(19, 'Airdots', 16, '1300.00', 110, '2020-04-27 20:28:50', 1, 1, 'img_producto.jpg');

--
-- Disparadores `producto`
--
DELIMITER $$
CREATE TRIGGER `entradas_A_I` AFTER INSERT ON `producto` FOR EACH ROW BEGIN
	INSERT INTO entradas(codproducto,cantidad,precio,usuario_id)
    VALUES(new.codproducto,new.existencia,new.precio,new.usuario_id);
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedor`
--

CREATE TABLE `proveedor` (
  `codproveedor` int(11) NOT NULL,
  `proveedor` varchar(100) DEFAULT NULL,
  `contacto` varchar(100) DEFAULT NULL,
  `telefono` bigint(10) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `date_add` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `proveedor`
--

INSERT INTO `proveedor` (`codproveedor`, `proveedor`, `contacto`, `telefono`, `direccion`, `date_add`, `usuario_id`, `estatus`) VALUES
(2, 'DELL', 'Felix Arnoldo Rojas', 8185748596, 'Avenida las Americas Zona 13', '2020-04-20 18:34:42', 3, 1),
(15, 'HP', 'Angel Cardona', 8584859685, '5ta calle zona 4', '2020-04-20 19:13:48', 1, 1),
(16, 'Huawei', 'Mariana Martinez', 8252829628, 'Av. México 406', '2020-04-21 13:10:21', 1, 1),
(17, 'ACER', 'Rodrigo Arenales', 8281748596, 'Calzada Buena Vista', '2020-04-21 17:32:45', 1, 1),
(18, 'RYZEN', 'Claudia Martinez', 8284857485, 'Sin definir', '2020-04-22 11:52:34', 1, 1),
(19, 'Logitech', 'Juana Martinez', 8285748596, 'Av. Mexico 107', '2020-04-27 18:08:20', 1, 1),
(20, 'Google', 'Karina Leal', 8182847596, 'Av. Nuevo Sur 105', '2020-04-27 20:22:37', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rol`
--

CREATE TABLE `rol` (
  `idrol` int(11) NOT NULL,
  `rol` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `rol`
--

INSERT INTO `rol` (`idrol`, `rol`) VALUES
(1, 'Administrador'),
(2, 'Supervisor'),
(3, 'Vendedor');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `idusuario` int(11) NOT NULL,
  `nombre` varchar(50) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL,
  `usuario` varchar(15) DEFAULT NULL,
  `clave` varchar(100) DEFAULT NULL,
  `rol` int(11) DEFAULT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`idusuario`, `nombre`, `correo`, `usuario`, `clave`, `rol`, `estatus`) VALUES
(1, 'Eduardo Banda', 'eduardo@gmail.com', 'Eduardo', '81dc9bdb52d04dc20036dbd8313ed055', 1, 1),
(2, 'Daniela Martinez', 'danielam@gmail.com', 'daniela', '202cb962ac59075b964b07152d234b70', 3, 1),
(3, 'Osmar Ortiz', 'osmar@gmail.com', 'osmar', '202cb962ac59075b964b07152d234b70', 2, 1),
(4, 'Arely Robles', 'arely@gmail.com', 'arely', 'fd23073d0cfdcd1748f1fcd8d03ca903', 3, 1),
(5, 'Daniel Morales', 'daniel@gmail.com', 'daniel', '202cb962ac59075b964b07152d234b70', 3, 1),
(7, 'Oscar Lopez', 'oscar@gmail.com', 'oscar', '202cb962ac59075b964b07152d234b70', 3, 1),
(8, 'Adolfo Calderon', 'adolfo@gmail.com', 'adolfo', '202cb962ac59075b964b07152d234b70', 3, 1),
(9, 'Karina Frias', 'karina@gmail.com', 'karina', 'a0a080f42e6f13b3a2df133f073095dd', 3, 1),
(10, 'Gustavo Sanchez', 'gustavo@gmail.com', 'gustavo', '202cb962ac59075b964b07152d234b70', 3, 0),
(11, 'Vania Vitela', 'vania@gmail.com', 'vania', '81dc9bdb52d04dc20036dbd8313ed055', 3, 1),
(12, 'Cesar Fraire', 'cesar@gmail.com', 'cesar', '202cb962ac59075b964b07152d234b70', 3, 1),
(13, 'Rene Cantú', 'rene@gmail.com', 'rene', '202cb962ac59075b964b07152d234b70', 3, 1),
(14, 'Kimberly Cantu', 'kimberly@gmail.com', 'kimberly', '202cb962ac59075b964b07152d234b70', 3, 1),
(15, 'Roberto de Leon', 'roberto@gmail.com', 'roberto', '202cb962ac59075b964b07152d234b70', 3, 1);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`idcliente`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `configuracion`
--
ALTER TABLE `configuracion`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `detallefactura`
--
ALTER TABLE `detallefactura`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `codproducto` (`codproducto`),
  ADD KEY `nofactura` (`nofactura`);

--
-- Indices de la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `nofactura` (`token_user`),
  ADD KEY `codproducto` (`codproducto`);

--
-- Indices de la tabla `entradas`
--
ALTER TABLE `entradas`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `codproducto` (`codproducto`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `factura`
--
ALTER TABLE `factura`
  ADD PRIMARY KEY (`nofactura`),
  ADD KEY `usuario` (`usuario`),
  ADD KEY `codcliente` (`codcliente`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`codproducto`),
  ADD KEY `proveedor` (`proveedor`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD PRIMARY KEY (`codproveedor`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `rol`
--
ALTER TABLE `rol`
  ADD PRIMARY KEY (`idrol`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`idusuario`),
  ADD KEY `rol` (`rol`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `idcliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT de la tabla `configuracion`
--
ALTER TABLE `configuracion`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `detallefactura`
--
ALTER TABLE `detallefactura`
  MODIFY `correlativo` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=99;

--
-- AUTO_INCREMENT de la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  MODIFY `correlativo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=95;

--
-- AUTO_INCREMENT de la tabla `entradas`
--
ALTER TABLE `entradas`
  MODIFY `correlativo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT de la tabla `factura`
--
ALTER TABLE `factura`
  MODIFY `nofactura` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `codproducto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  MODIFY `codproveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla `rol`
--
ALTER TABLE `rol`
  MODIFY `idrol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `idusuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `cliente_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`);

--
-- Filtros para la tabla `detallefactura`
--
ALTER TABLE `detallefactura`
  ADD CONSTRAINT `detallefactura_ibfk_1` FOREIGN KEY (`nofactura`) REFERENCES `factura` (`nofactura`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `detallefactura_ibfk_2` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  ADD CONSTRAINT `detalle_temp_ibfk_2` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `entradas`
--
ALTER TABLE `entradas`
  ADD CONSTRAINT `entradas_ibfk_1` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `factura`
--
ALTER TABLE `factura`
  ADD CONSTRAINT `factura_ibfk_1` FOREIGN KEY (`usuario`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `factura_ibfk_2` FOREIGN KEY (`codcliente`) REFERENCES `cliente` (`idcliente`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `producto`
--
ALTER TABLE `producto`
  ADD CONSTRAINT `producto_ibfk_1` FOREIGN KEY (`proveedor`) REFERENCES `proveedor` (`codproveedor`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `producto_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD CONSTRAINT `proveedor_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD CONSTRAINT `usuario_ibfk_1` FOREIGN KEY (`rol`) REFERENCES `rol` (`idrol`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
