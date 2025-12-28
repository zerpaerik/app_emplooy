# Clock-In Module Setup Guide

## iOS Configuration

Para que el módulo Clock-In funcione correctamente en iOS, necesitas agregar permisos de ubicación al archivo `ios/Runner/Info.plist`:

```xml
<!-- Agregar estas líneas dentro del tag <dict> -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location when open to track work locations.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to location to track work locations.</string>
```

## Funcionalidades Implementadas

### ✅ Validación de Workday
- Verifica si hay una jornada activa
- Estados: Not Started, Setup, Active, Finished
- Navegación inteligente según estado

### ✅ Setup de Jornada
- Configuración de fecha y hora de entrada
- Input de temperatura corporal
- Modo automático vs manual
- Validaciones de datos

### ✅ Dashboard de Clocking
- Progreso en tiempo real
- Métricas de workers (scanned, absent, pending)
- Botón flotante para escanear QR
- Finalización de sesión

### ✅ Datos Simulados
- 3 workers de ejemplo para testing
- Estados de workday simulados
- Funciona sin conexión a API

## Flujo de Usuario

1. **Dashboard Principal** → Click en "Clock In" (solo supervisores)
2. **Validation Page** → Verifica estado del workday
3. **Setup Page** → Configura jornada si es necesario
4. **Dashboard Page** → Gestiona el proceso de clocking

## Navegación

```
Dashboard → Clock In → Validation → Setup → Dashboard
```

## Testing

El módulo está configurado con datos simulados para permitir testing sin backend:

- **Workers**: Juan Pérez, María García, Carlos López
- **Workday**: Estado inicial "Not Started"
- **Ubicación**: Manejo de errores sin bloquear flujo

## Próximos Pasos

1. **Sprint 2**: Implementar escáner QR
2. **Sprint 3**: Conectar con APIs reales
3. **Sprint 4**: Testing y refinamiento

## Troubleshooting

### Error de Geolocator en iOS
- **Problema**: MissingPluginException
- **Solución**: Agregar permisos en Info.plist
- **Workaround**: El código maneja errores sin bloquear

### Datos No Cargan
- **Verificar**: Que el usuario tenga rol supervisor
- **Verificar**: Que el módulo clockInModule esté activo
- **Fallback**: Datos simulados siempre disponibles
