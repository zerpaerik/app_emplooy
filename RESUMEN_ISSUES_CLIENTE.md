# RESUMEN EJECUTIVO - ISSUES MÓDULO CLOCK-IN/OUT
## Emplooy App - Diciembre 2025

---

## 📊 ESTADO GENERAL

**Total de Issues Identificados:** 12  
**Issues Críticos:** 3  
**Issues Altos:** 2  
**Issues Medios:** 7  

---

## 🔴 ISSUES CRÍTICOS (Requieren Atención Inmediata)

### **1. Scroll No Funciona en Dashboard Principal**
- **Problema:** Los usuarios no pueden desplazarse hacia abajo en el dashboard. Si el botón "Start Clock In" queda fuera de la pantalla, es inaccesible.
- **Causa:** El widget `DashboardWorker` no tiene scroll interno funcional.
- **Impacto:** Funcionalidad básica inaccesible en pantallas pequeñas.
- **Prioridad:** 🔴 CRÍTICA

### **6. Lista de Ausentes Muestra Todos los Usuarios**
- **Problema:** El contador muestra "Ausentes (2)" correctamente, pero al abrir la lista aparecen TODOS los usuarios, no solo los 2 ausentes.
- **Causa:** Error en el filtrado de la lista de workers ausentes.
- **Impacto:** Información incorrecta que confunde al supervisor.
- **Prioridad:** 🔴 CRÍTICA

### **9. Múltiples "Backs" Necesarios Después de Escanear**
- **Problema:** Si se escanean 5 QRs, hay que presionar "back" 5 veces para regresar al dashboard.
- **Causa:** Cada scan agrega una ruta al stack de navegación sin limpiar las anteriores.
- **Impacto:** Navegación extremadamente frustrante.
- **Prioridad:** 🔴 CRÍTICA

---

## 🟠 ISSUES ALTOS (Resolver Pronto)

### **3. No Pregunta Hora de Entrada Individual**
- **Problema:** Después de escanear a Jim, al escanear a Eva el sistema no pregunta su hora de entrada y asume la misma de Jim. Además, genera errores al intentar cambiarla.
- **Causa:** El sistema guarda un tiempo global que se reutiliza para todos los workers.
- **Impacto:** Datos incorrectos de clock-in para workers subsecuentes.
- **Prioridad:** 🟠 ALTA

### **10. Segundo Lead No Ve Opción de Clock-Out**
- **Problema:** Cuando hay múltiples supervisores, el segundo supervisor no puede ver la opción para hacer su clock-out.
- **Causa:** La verificación solo chequea si "algún" supervisor hizo clock-in, no si "este supervisor específico" lo hizo.
- **Impacto:** Segundo supervisor no puede completar su jornada.
- **Prioridad:** 🟠 ALTA

---

## 🟡 ISSUES MEDIOS (Resolver en Próximo Sprint)

### **2. Rank Time con Dos Líneas en Algunos Teléfonos**
- **Problema:** La sección "Rank Time" muestra información en dos líneas en pantallas pequeñas.
- **Causa:** Falta manejo de overflow y restricciones de ancho en los textos.
- **Prioridad:** 🟡 MEDIA

### **4. No Pregunta Hora Después del Minuto**
- **Problema:** El sistema no pregunta la hora de clock-in después de que pasa 1 minuto desde el último scan.
- **Causa:** El timer expira y regresa al dashboard sin mostrar el diálogo de actualización.
- **Prioridad:** 🟡 MEDIA

### **7. Auto Clock In/Out No Funciona**
- **Problema:** La opción de "Auto Clock In" con el switch no funciona ni en clock-in ni en clock-out.
- **Causa:** El flag se envía al backend pero no hay lógica en el frontend para ejecutar el clock-in automático del supervisor.
- **Prioridad:** 🟡 MEDIA

### **11. No Permite Cambiar Hora Después del Primer Minuto**
- **Problema:** En clock-out, después del primer minuto, el sistema no permite cambiar la hora y siempre usa la primera.
- **Causa:** El tiempo se guarda globalmente y se reutiliza sin permitir cambios individuales.
- **Prioridad:** 🟡 MEDIA

### **12. No Pregunta Si Quiere Hacer Clock In/Out al Finalizar**
- **Problema:** Al finalizar el proceso, si el supervisor no tiene su propio clock-in/out, el sistema no pregunta si desea hacerlo.
- **Causa:** El método de verificación puede tener un bug o no se está llamando correctamente.
- **Prioridad:** 🟡 MEDIA

---

## 📋 MATRIZ DE PRIORIDADES

| Issue | Descripción Corta | Severidad | Esfuerzo Estimado |
|-------|-------------------|-----------|-------------------|
| #1 | Scroll dashboard | 🔴 CRÍTICA | 2-3 horas |
| #6 | Ausentes incorrectos | 🔴 CRÍTICA | 1-2 horas |
| #9 | Múltiples backs | 🔴 CRÍTICA | 2-3 horas |
| #3 | Hora individual | 🟠 ALTA | 3-4 horas |
| #10 | Segundo lead | 🟠 ALTA | 2-3 horas |
| #2 | Rank time layout | 🟡 MEDIA | 1 hora |
| #4 | Pregunta hora | 🟡 MEDIA | 2 horas |
| #7 | Auto clock in | 🟡 MEDIA | 2-3 horas |
| #11 | Cambiar hora | 🟡 MEDIA | 2 horas |
| #12 | Pregunta final | 🟡 MEDIA | 1-2 horas |

---

## 🎯 RECOMENDACIONES

### **Sprint Inmediato (Esta Semana)**
Resolver los 3 issues críticos:
1. Implementar scroll funcional en dashboard
2. Corregir filtro de workers ausentes
3. Limpiar stack de navegación después de cada scan

**Tiempo Estimado:** 5-8 horas de desarrollo + testing

### **Sprint Siguiente (Próxima Semana)**
Resolver los 2 issues altos:
1. Implementar manejo individual de horas por worker
2. Corregir lógica de múltiples supervisores

**Tiempo Estimado:** 5-7 horas de desarrollo + testing

### **Backlog (Próximas 2 Semanas)**
Resolver los 7 issues medios en orden de impacto en UX.

**Tiempo Estimado:** 10-15 horas de desarrollo + testing

---

## 📝 NOTAS TÉCNICAS IMPORTANTES

1. **Navegación:** Se recomienda refactorizar el sistema de navegación para usar `Navigator.pushAndRemoveUntil()` o implementar un patrón de navegación más robusto.

2. **Manejo de Estado:** El sistema actual usa un estado global para tiempos que causa múltiples problemas. Se recomienda implementar un sistema que maneje tiempos individuales por worker.

3. **Testing:** Es crítico implementar pruebas en múltiples dispositivos con diferentes tamaños de pantalla (especialmente < 6 pulgadas).

4. **Logging:** Agregar más logs para facilitar debugging de problemas de timing y estado.

---

## 📞 PRÓXIMOS PASOS

1. **Validación con Cliente:** Confirmar prioridades y orden de resolución
2. **Planning:** Asignar issues a sprints específicos
3. **Desarrollo:** Comenzar con issues críticos
4. **Testing:** Pruebas exhaustivas en múltiples dispositivos
5. **Deploy:** Actualización gradual con monitoreo

---

**Documento Preparado Por:** Equipo de Desarrollo Emplooy  
**Fecha:** 30 de Diciembre, 2025  
**Versión:** 1.0

Para análisis técnico detallado de cada issue, consultar: `ANALISIS_ISSUES_CLOCKIN.md`
