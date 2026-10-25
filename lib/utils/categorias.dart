import 'package:flutter/material.dart';

import '../models/movimiento.dart';

const String kCatCobroDeudas = 'Cobro de deudas';
const String kCatPagoDeudas = 'Pago de deudas';

const List<String> kCategoriasIngreso = [
  'Salario',
  'Ventas',
  'Negocio',
  'Freelance',
  'Inversiones',
  'Regalos',
  kCatCobroDeudas,
  'Otros ingresos',
];

const List<String> kCategoriasEgreso = [
  'Comida',
  'Supermercado',
  'Transporte',
  'Combustible',
  'Vivienda',
  'Servicios',
  'Salud',
  'Educación',
  'Entretenimiento',
  'Ropa',
  'Suscripciones',
  kCatPagoDeudas,
  'Otros gastos',
];

List<String> categoriasDe(TipoMovimiento tipo) =>
    tipo == TipoMovimiento.ingreso ? kCategoriasIngreso : kCategoriasEgreso;

const Map<String, IconData> _iconos = {
  'Salario': Icons.work_outline,
  'Ventas': Icons.storefront_outlined,
  'Negocio': Icons.business_center_outlined,
  'Freelance': Icons.laptop_outlined,
  'Inversiones': Icons.trending_up,
  'Regalos': Icons.card_giftcard_outlined,
  kCatCobroDeudas: Icons.call_received,
  'Otros ingresos': Icons.add_circle_outline,
  'Comida': Icons.restaurant_outlined,
  'Supermercado': Icons.shopping_cart_outlined,
  'Transporte': Icons.directions_bus_outlined,
  'Combustible': Icons.local_gas_station_outlined,
  'Vivienda': Icons.home_outlined,
  'Servicios': Icons.bolt_outlined,
  'Salud': Icons.medical_services_outlined,
  'Educación': Icons.school_outlined,
  'Entretenimiento': Icons.movie_outlined,
  'Ropa': Icons.checkroom_outlined,
  'Suscripciones': Icons.subscriptions_outlined,
  kCatPagoDeudas: Icons.call_made,
  'Otros gastos': Icons.more_horiz,
};

IconData iconoCategoria(String categoria) =>
    _iconos[categoria] ?? Icons.label_outline;

const Color kColorIngreso = Color(0xFF2E7D32);
const Color kColorEgreso = Color(0xFFC62828);

Color colorTipo(TipoMovimiento tipo) =>
    tipo == TipoMovimiento.ingreso ? kColorIngreso : kColorEgreso;
