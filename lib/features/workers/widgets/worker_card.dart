import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/worker_model.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback onTap;

  const WorkerCard({
    Key? key,
    required this.worker,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícono de check verde
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              
              // Información del worker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BTN ID
                    Text(
                      'ID# ${worker.btnId}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Nombre completo
                    Text(
                      worker.fullName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    // Posición (si existe)
                    if (worker.position != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        worker.position!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Ícono de flecha
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textGrey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
