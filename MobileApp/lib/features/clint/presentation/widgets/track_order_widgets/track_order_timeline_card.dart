import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_status_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TrackOrderTimelineCard extends StatelessWidget {
  const TrackOrderTimelineCard({
    super.key,
    required this.steps,
    required this.fontFamily,
  });

  final List<TrackOrderStepData> steps;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++)
            _TimelineRow(
              step: steps[index],
              fontFamily: fontFamily,
              showConnector: index < steps.length - 1,
              connectorColor: index < steps.length - 1
                  ? _connectorColor(steps[index], steps[index + 1])
                  : const Color(0xFFD0D5DD),
            ),
        ],
      ),
    );
  }

  Color _connectorColor(TrackOrderStepData current, TrackOrderStepData next) {
    if (current.state == TrackOrderStepState.pending ||
        next.state == TrackOrderStepState.pending) {
      return const Color(0xFF333333).withOpacity(.5);
    }
    return const Color(0xFF3A7DC5);
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.fontFamily,
    required this.showConnector,
    required this.connectorColor,
  });

  final TrackOrderStepData step;
  final String fontFamily;
  final bool showConnector;
  final Color connectorColor;

  @override
  Widget build(BuildContext context) {
    final isPending = step.state == TrackOrderStepState.pending;
    final titleColor = isPending
        ? const Color(0xFF333333).withValues(alpha: 0.6)
        : const Color(0xFF333333);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 20.h : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: titleColor,
                      fontFamily: fontFamily,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (true) ...[
                    SizedBox(height: 4.h),
                    Text(
                      step.date != null ? step.date! : '',
                      style: TextStyle(
                        color: const Color(0xFF333333).withValues(alpha: 0.55),
                        fontFamily: fontFamily,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                  if (step.subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      step.subtitle != null ? step.subtitle! : '',
                      style: TextStyle(
                        color: const Color(0xFF3A7DC5),
                        fontFamily: fontFamily,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Column(
            children: [
              _StepIcon(state: step.state),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2.w,
                    margin: EdgeInsets.symmetric(vertical: 6.h),
                    color: connectorColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.state});

  final TrackOrderStepState state;

  @override
  Widget build(BuildContext context) {
    final isPending = state == TrackOrderStepState.pending;
    final bgColor = isPending
        ? const Color(0xFFE0F1FF)
        : const Color(0xFFE0F1FF);

    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFE1E3E5) : bgColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      alignment: Alignment.center,
      child: _buildIcon(),
    );
  }

  Widget _buildIcon() {
    switch (state) {
      case TrackOrderStepState.completed:
        return Icon(
          Icons.check_rounded,
          size: 22.sp,
          color: const Color(0xFF3A7DC5),
        );
      case TrackOrderStepState.inProgress:
        return SvgPicture.asset(
          AppAssets.clockIcon,
          width: 20.w,
          height: 20.h,
          colorFilter: const ColorFilter.mode(
            Color(0xFF3A7DC5),
            BlendMode.srcIn,
          ),
        );
      case TrackOrderStepState.pending:
        return SvgPicture.asset(
          "assets/icons/box11.svg",
          width: 25.w,
          height: 25.h,
        );
    }
  }
}
