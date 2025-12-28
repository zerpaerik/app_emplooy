# ANÁLISIS DEL FLUJO DE WORKDAY REPORT SEGÚN WORKER

## FLUJO CORRECTO:

### STEP 0 - Base (NewWorkdayReportBase)
**Pregunta:** ¿Hubo jornada de trabajo?
- Radio: Sí / No

**Si SÍ:**
1. Obtiene el clockIn más temprano de `/api/v-1/workday/{workdayId}/clock-in/list`
2. Obtiene el clockOut más tardío de `/api/v-1/workday/{workdayId}/clock-out/list`
3. Crea reporte base con: `addWorkdayReportBase(workday_id, clockIn, clockOut, start_time, end_time)`
4. Endpoint: POST `/api/v-1/workday/{workdayId}/workday-report/create`
5. Recibe `report_id` en respuesta
6. Navega a STEP 1 con `report_id`

**Si NO:**
1. Crea reporte sin jornada: `addWorkdayReportNOJ(workday)`
2. Termina el proceso

---

### STEP 1 - Lunch Time (NewWorkdayReport1)
**Recibe:** `report_id` del Step 0

**Pregunta:** ¿Hubo tiempo de lunch?
- Radio: Sí / No

**Si SÍ:**
- Input: Duración en minutos (TextField)

**Acción:**
- Actualiza reporte: `editWorkdayReport1(hourClock, hourClock1, durationLunch, report_id)`
- Endpoint: PATCH `/api/v-1/workday/workday-report/{report_id}/update`
- Navega a STEP 2

---

### STEP 2 - Standby Time (NewWorkdayReport2)
**Recibe:** `report_id`

**Pregunta:** ¿Hubo tiempo de standby?
- Radio: Sí / No

**Si SÍ:**
- Time Picker: Hora de inicio
- Time Picker: Hora de fin

**Acción:**
- Actualiza reporte: `editWorkdayReport2(standby_start, standby_end, durationStandBy, report_id)`
- Endpoint: PATCH `/api/v-1/workday/workday-report/{report_id}/update`
- Navega a STEP 3

---

### STEP 3 - Travel Time (NewWorkdayReport3)
**Recibe:** `report_id`

**Pregunta:** ¿Hubo tiempo de viaje al sitio de trabajo?
- Radio: Sí / No

**Si SÍ:**
- Time Picker: Hora de inicio
- Time Picker: Hora de fin

**Acción:**
- Actualiza reporte: `editWorkdayReport3(travel_start, travel_end, durationTravel, report_id)`
- Endpoint: PATCH `/api/v-1/workday/workday-report/{report_id}/update`
- Navega a STEP 4

---

### STEP 4 - Comentarios Finales (NewWorkdayReport4)
**Recibe:** `report_id`

**Contenido:**
- TextField: Comentarios finales (opcional)

**Acción:**
- Actualiza reporte: `editWorkdayReport4(comments, report_id)`
- Endpoint: PATCH `/api/v-1/workday/workday-report/{report_id}/update`
- Finaliza y navega al Dashboard

---

## ENDPOINTS CORRECTOS:

1. **Crear reporte base:**
   - POST `/api/v-1/workday/{workdayId}/workday-report/create`
   - Body: `{ workday_id, start_time, end_time }`

2. **Actualizar reporte:**
   - PATCH `/api/v-1/workday/workday-report/{reportId}/update`
   - Body: Campos a actualizar

3. **Eliminar reporte:**
   - DELETE `/api/v-1/workday/workday-report/{reportId}/delete`

4. **Listar reportes:**
   - GET `/api/v-1/workday/{workdayId}/workday-report/worker-report/`

5. **Clock-in list:**
   - GET `/api/v-1/workday/{workdayId}/clock-in/list`

6. **Clock-out list:**
   - GET `/api/v-1/workday/{workdayId}/clock-out/list`

---

## CORRECCIONES NECESARIAS:

1. ✅ Workers endpoint ya está correcto: `/api/v-1/crew/{contractId}/workers`

2. ❌ Workday Reports: Necesita usar workdayId, no contractId

3. ❌ Rediseñar steps:
   - Step 0: Pregunta inicial + crear reporte base
   - Step 1: Lunch (Sí/No + duración)
   - Step 2: Standby (Sí/No + horas)
   - Step 3: Travel (Sí/No + horas)
   - Step 4: Comentarios finales

4. ❌ Implementar creación en Step 0 y actualización en Steps 1-4

5. ❌ Usar clockIn/clockOut del workday (no editables)

6. ❌ Implementar radio buttons Sí/No para cada tipo de tiempo
