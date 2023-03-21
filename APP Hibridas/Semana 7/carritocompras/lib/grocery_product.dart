import 'package:flutter/material.dart';

class GroceryProduct {
  const GroceryProduct({
    required this.price,
    required this.name,
    required this.description,
    required this.image,
    required this.weight,
  });

  final double price;
  final String name;
  final String description;
  final String image;
  final String weight;
}

const grpceryProducts = <GroceryProduct>[
  GroceryProduct(
      price: 99.99,
      name: 'Aguacate',
      description:
          'Persea americana, llamado popularmente aguacate, ​​​ palto ​​ o aguacatero, ​ es una especie arbórea del género Persea perteneciente a la familia Lauraceae, cuyo fruto, el aguacate​​ o palta, ​​ es una baya comestible.​',
      image: 'assets/grocery_store/aguacate.jpg',
      weight: '1kg'),
  GroceryProduct(
      price: 18.57,
      name: 'Platano',
      description:
          'La banana, ​ conocido también como banano, plátano, ​ guineo maduro, guineo, cambur o gualele, es un fruto comestible, de varios tipos de grandes plantas herbáceas del género Musa.​',
      image: 'assets/grocery_store/platano.jpg',
      weight: '1kg'),
  GroceryProduct(
      price: 31.58,
      name: 'Mango',
      description:
          'El mango es una de las frutas de temporada más ricas, ya que sus propiedades y sabor lo hace idóneo como ingrediente en recetas de desayunos nutritivos.',
      image: 'assets/grocery_store/mango.jpg',
      weight: '1kg'),
  GroceryProduct(
      price: 19.99,
      name: 'Piña',
      description:
          'Ananas comosus es una especie de la familia de las bromeliáceas, nativa de América del Sur. Planta de escaso porte y con hojas duras y lanceoladas de hasta 1 m de largo, fructifica una vez al año produciendo un único fruto fragante y dulce, muy apreciado en gastronomía.',
      image: 'assets/grocery_store/piña.jpg',
      weight: '1kg'),
  GroceryProduct(
      price: 340.95,
      name: 'Cereza',
      description:
          'Los cerezos pertenecen a la familia de las rosáceas, del género prunus, como el albaricoque, la ciruela o el melocotón.',
      image: 'assets/grocery_store/cereza.png',
      weight: '1kg'),
  GroceryProduct(
      price: 36.91,
      name: 'Naranja',
      description:
          'La naranja es una fruta cítrica obtenida del naranjo dulce, del naranjo amargo y de naranjos de otras variedades o híbridos, de origen asiático.​',
      image: 'assets/grocery_store/naranja.jpg',
      weight: '1kg'),
  GroceryProduct(
      price: 16.55,
      name: 'Sandia',
      description:
          'Citrullus lanatus, comúnmente llamada sandía, acendría, sindria, patilla, es una especie de la familia Cucurbitaceae. Es originaria de África con una gran presencia y difusión en todo el mundo.',
      image: 'assets/grocery_store/sandia.jpg',
      weight: '1kg'),
];
