-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1:3306
-- Tiempo de generación: 05-06-2023 a las 14:25:25
-- Versión del servidor: 8.0.31
-- Versión de PHP: 8.0.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `proyecto`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `con45c1f1`
--

DROP TABLE IF EXISTS `con45c1f1`;
CREATE TABLE IF NOT EXISTS `con45c1f1` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `conProducto` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `con45c1f2`
--

DROP TABLE IF EXISTS `con45c1f2`;
CREATE TABLE IF NOT EXISTS `con45c1f2` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `conProducto` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `con45c1f3`
--

DROP TABLE IF EXISTS `con45c1f3`;
CREATE TABLE IF NOT EXISTS `con45c1f3` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `conProducto` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `con45c2f1`
--

DROP TABLE IF EXISTS `con45c2f1`;
CREATE TABLE IF NOT EXISTS `con45c2f1` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `conProducto` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `con45c2f2`
--

DROP TABLE IF EXISTS `con45c2f2`;
CREATE TABLE IF NOT EXISTS `con45c2f2` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `conProducto` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `con45c2f3`
--

DROP TABLE IF EXISTS `con45c2f3`;
CREATE TABLE IF NOT EXISTS `con45c2f3` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `conProducto` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `con45c3f1`
--

DROP TABLE IF EXISTS `con45c3f1`;
CREATE TABLE IF NOT EXISTS `con45c3f1` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `conProducto` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `con45c3f2`
--

DROP TABLE IF EXISTS `con45c3f2`;
CREATE TABLE IF NOT EXISTS `con45c3f2` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `conProducto` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `con45c3f3`
--

DROP TABLE IF EXISTS `con45c3f3`;
CREATE TABLE IF NOT EXISTS `con45c3f3` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `conProducto` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `contenedores`
--

DROP TABLE IF EXISTS `contenedores`;
CREATE TABLE IF NOT EXISTS `contenedores` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codContenedor` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=46 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `contenedores`
--

INSERT INTO `contenedores` (`id`, `codContenedor`) VALUES
(45, '6c8349cc7260ae62e3b1396831a8398f');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

DROP TABLE IF EXISTS `productos`;
CREATE TABLE IF NOT EXISTS `productos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo_de_barras` varchar(255) NOT NULL,
  `nombre` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id`, `codigo_de_barras`, `nombre`) VALUES
(18, 'ASDFG', 'PEPSI'),
(17, 'QWERTY', 'COCA COLA');
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
