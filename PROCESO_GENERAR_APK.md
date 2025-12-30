# PROCESO CORRECTO PARA GENERAR APK CON CAMBIOS

## ✅ RESPUESTA: SÍ, SIEMPRE HACER FLUTTER CLEAN

**Cuando envías un APK al usuario para pruebas, SIEMPRE debes hacer `flutter clean` antes de generar el APK**, especialmente cuando hay cambios en:
- Navegación
- Estado (Providers/Riverpod)
- Modelos de datos
- Dependencias
- Assets o recursos

---

## 🔧 PROCESO COMPLETO PASO A PASO

### **1. Asegurar que todos los cambios estén commiteados**

```bash
cd /Users/erikzerpa/Documents/EMPLOOY_LLC/emplooy_app

# Ver estado de git
git status

# Si hay cambios sin commitear, hacerlo
git add -A
git commit -m "fix: Descripción de los cambios"
git push origin main
```

### **2. Limpiar completamente el proyecto**

```bash
# Limpiar caché de Flutter (CRÍTICO)
fvm flutter clean

# Opcional pero recomendado: Limpiar caché de pub
fvm flutter pub cache repair

# Obtener dependencias limpias
fvm flutter pub get
```

### **3. Limpiar caché de Gradle (Android)**

```bash
# Ir a carpeta android
cd android

# Limpiar Gradle
./gradlew clean

# Regresar a raíz
cd ..
```

### **4. Generar APK de Release**

```bash
# Generar APK limpio en modo release
fvm flutter build apk --release

# O si quieres APK split por ABI (más pequeños):
fvm flutter build apk --release --split-per-abi
```

### **5. Ubicación del APK generado**

El APK estará en:
```
build/app/outputs/flutter-apk/app-release.apk
```

O si usaste `--split-per-abi`:
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

---

## 🚀 SCRIPT COMPLETO (COPIAR Y PEGAR)

```bash
#!/bin/bash
# Script para generar APK limpio con todos los cambios

echo "🔧 Limpiando proyecto..."
cd /Users/erikzerpa/Documents/EMPLOOY_LLC/emplooy_app
fvm flutter clean

echo "📦 Obteniendo dependencias..."
fvm flutter pub get

echo "🧹 Limpiando Gradle..."
cd android
./gradlew clean
cd ..

echo "🏗️ Generando APK de release..."
fvm flutter build apk --release

echo "✅ APK generado en: build/app/outputs/flutter-apk/app-release.apk"
echo "📱 Listo para enviar al usuario"
```

**Guardar como:** `generate_clean_apk.sh`

**Ejecutar:**
```bash
chmod +x generate_clean_apk.sh
./generate_clean_apk.sh
```

---

## ⚠️ IMPORTANTE: POR QUÉ ES NECESARIO

### **Sin `flutter clean`:**
- ❌ El APK puede contener código antiguo cacheado
- ❌ Los cambios en navegación pueden no aplicarse
- ❌ Los cambios en providers pueden no reflejarse
- ❌ Puede haber conflictos de versiones
- ❌ El usuario verá bugs que ya fueron corregidos

### **Con `flutter clean`:**
- ✅ APK completamente limpio
- ✅ Todos los cambios incluidos
- ✅ Sin caché antiguo
- ✅ Sin conflictos
- ✅ El usuario ve la versión correcta

---

## 📋 CHECKLIST ANTES DE ENVIAR APK

- [ ] Todos los cambios commiteados en git
- [ ] `fvm flutter clean` ejecutado
- [ ] `fvm flutter pub get` ejecutado
- [ ] `./gradlew clean` ejecutado en carpeta android
- [ ] APK generado con `--release`
- [ ] APK probado en emulador/dispositivo físico
- [ ] Versión incrementada en `pubspec.yaml` (opcional pero recomendado)
- [ ] Changelog documentado

---

## 🔢 INCREMENTAR VERSIÓN (RECOMENDADO)

Antes de generar el APK, incrementar la versión en `pubspec.yaml`:

```yaml
version: 1.0.0+1  # Cambiar a 1.0.1+2 (por ejemplo)
```

Formato: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

---

## 📱 ENVIAR APK AL USUARIO

### **Opción 1: Google Drive / Dropbox**
```bash
# Copiar APK a carpeta compartida
cp build/app/outputs/flutter-apk/app-release.apk ~/Google\ Drive/Emplooy/APKs/emplooy-v1.0.1.apk
```

### **Opción 2: Email**
- Adjuntar el APK directamente
- Incluir notas de la versión

### **Opción 3: TestFlight / Firebase App Distribution**
- Más profesional para testing continuo

---

## 🐛 SI EL USUARIO REPORTA QUE LOS CAMBIOS NO SE VEN

1. **Verificar que instaló el APK correcto:**
   - Pedirle que desinstale la app completamente
   - Reinstalar desde el nuevo APK

2. **Verificar versión:**
   - En la app, ir a Settings → About
   - Verificar número de versión

3. **Limpiar datos de la app:**
   - Configuración → Apps → Emplooy → Borrar datos
   - Desinstalar y reinstalar

---

## 📝 PARA ESTE CASO ESPECÍFICO

**Cambios aplicados hoy (30 Dic 2025):**
1. Navegación múltiples scans corregida
2. Scroll en dashboard corregido
3. Filtro de ausentes verificado

**Proceso recomendado:**

```bash
# 1. Commit de cambios (ya hecho)
git add -A
git commit -m "fix: Issues críticos corregidos"
git push origin main

# 2. Limpiar y generar APK
fvm flutter clean
fvm flutter pub get
cd android && ./gradlew clean && cd ..
fvm flutter build apk --release

# 3. El APK estará en:
# build/app/outputs/flutter-apk/app-release.apk

# 4. Enviar al usuario con nota:
# "APK con correcciones de navegación y scroll. 
#  Por favor desinstalar app anterior antes de instalar esta."
```

---

## ✅ RESUMEN

**SÍ, SIEMPRE hacer `flutter clean` antes de generar APK con cambios.**

Es el único modo de garantizar que el APK contenga todos los cambios y no tenga caché antiguo que cause problemas.

**Tiempo estimado del proceso completo:** 5-10 minutos
