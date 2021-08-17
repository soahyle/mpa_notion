import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter/material.dart';

import '../common.dart' show NotionColors;
import '../utils.dart' show NaNToZero;
import 'models.dart';
import 'repository.dart';

export 'models.dart';
export 'repository.dart';

class GoalTrackerController extends GetxController {
  final GoalTrackerRepository _goalTrackerRepository = Get.find<GoalTrackerRepository>();

  final RxBool _loading = false.obs;

  final RxList<Goal> _goals = <Goal>[].obs;

  /// The goals in memory. The controller is responsible of keeping these
  /// in sync with the users in [repository].
  List<Goal> get goals => _goals;

  bool get loading => _loading.value;

  onInit() {
    super.onInit();
    loadUsers();
  }

  loadUsers() async {
    _loading.value = true;

    try {
      _goals(await _goalTrackerRepository.fetchGoals());
    } catch (e) {
      // TODO: It is almost always important the user knows about failures like these.
      // For simplicity, we're not doing it here, but in a real app, the
      // controller would deal with this.
      _goals(<Goal>[]);
    } finally {
      _loading.value = false;
    }
  }
}

class GoalTrackerView extends GetView<GoalTrackerController> {
  Color getColor(String color) {
    if (color == "blue") return NotionColors.fgBlue;
    if (color == "orange") return NotionColors.fgOrange;
    if (color == "purple") return NotionColors.fgPurple;
    return NotionColors.fgBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.loading) {
          return SizedBox(
            height: 16,
            width: 16,
            child: const CircularProgressIndicator(strokeWidth: 4, color: Color(0xff0060df)),
          ).centered();
        }

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: controller.goals.length,
          itemBuilder: (BuildContext context, int index) {
            return [
              VxBox(child: Text(''))
                  .height(10)
                  .width(MediaQuery.of(context).size.width)
                  .color(getColor(controller.goals[index].categoryColor))
                  .make(),
              [
                GoalProgress(
                        percent: controller.goals[index].progress,
                        category: controller.goals[index].category)
                    .pOnly(top: 16, left: 16),
                Flexible(
                  // FIXME: Why though? Otherwise it looks pretty dorky
                  fit: FlexFit.tight,
                  child: [
                    GoalInfo(goal: controller.goals[index]),
                    SizedBox(height: 28),
                    TargetList(targets: controller.goals[index].targets)
                  ].column(crossAlignment: CrossAxisAlignment.start).pSymmetric(v: 18, h: 16),
                ),
                [
                  GoalCategory(
                      category: controller.goals[index].category,
                      color: getColor(controller.goals[index].categoryColor)),
                  SizedBox(height: 8),
                  DueDate(date: controller.goals[index].date),
                ].column(crossAlignment: CrossAxisAlignment.end),
              ]
                  .row(
                    alignment: MainAxisAlignment.spaceBetween,
                    crossAlignment: CrossAxisAlignment.start,
                  )
                  .box
                  // .withConstraints(BoxConstraints(minWidth: double.infinity))
                  .make()
            ].column().card.rounded.color(Color(0xff040505)).make();
          },
        ).box.width(MediaQuery.of(context).size.width * 0.75).make().centered();

        // TODO: Handle error
        // else if (snapshot.hasError) return Text('${snapshot.error}');
      }),
    );
  }
}

// TODO: Different progres color according to their state
class GoalProgress extends StatelessWidget {
  const GoalProgress({Key? key, required this.percent, required this.category}) : super(key: key);

  final double percent;
  final String category;

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: 75,
      lineWidth: 7.5,
      percent: percent,
      center: '${(double.parse(percent.toStringAsFixed(2)) * 100).round()}%'.text.xl.make(),
      progressColor: Colors.green[500],
      circularStrokeCap: CircularStrokeCap.round,
    );
  }
}

class GoalInfo extends StatelessWidget {
  const GoalInfo({Key? key, required this.goal}) : super(key: key);

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    print('"${goal.name}"');

    // TODO: [OLD CODE] Why without Flexible the Goal's name align to the right???
    // https://stackoverflow.com/questions/54634093/flutter-wrap-text-instead-of-overflow
    return [
      goal.name.text.ellipsis.headline6(context).make(),
      SizedBox(height: 8),
      goal.description.text.subtitle2(context).make(),
    ].column(
      alignment: MainAxisAlignment.spaceEvenly,
      crossAlignment: CrossAxisAlignment.start,
    );
  }
}

class DueDate extends StatelessWidget {
  const DueDate({Key? key, required this.date}) : super(key: key);

  final String date;

  String get deadline {
    DateTime dateTimeCreatedAt = DateTime.tryParse(date) ?? DateTime.now();
    DateTime dateTimeNow = DateTime.now();
    final differenceInDays = dateTimeNow.difference(dateTimeCreatedAt).inDays;
    return (int.parse(differenceInDays.toString()) * -1).toString();
  }

  @override
  Widget build(BuildContext context) {
    return '🔥 ${deadline} days'.text.make().pOnly(right: 8);
  }
}

class GoalCategory extends StatelessWidget {
  const GoalCategory({Key? key, required this.category, required this.color}) : super(key: key);

  final String category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return category.text.lg
        .make()
        .pSymmetric(v: 1, h: 8)
        .box
        .color(color)
        .bottomLeftRounded(value: 6)
        .make();
  }
}

class TargetList extends StatelessWidget {
  const TargetList({Key? key, required this.targets}) : super(key: key);

  final List<Target> targets;

  @override
  Widget build(BuildContext context) {
    return targets
        .map((target) => [TargetItem(target: target), SizedBox(height: 8)])
        .expand((element) => element)
        .toList()
        .column(crossAlignment: CrossAxisAlignment.start);
  }
}

class TargetItem extends StatelessWidget {
  const TargetItem({Key? key, required this.target}) : super(key: key);

  final Target target;

  @override
  Widget build(BuildContext context) {
    return [
      [
        target.name.text.lg.subtitle1(context).make(),
        SizedBox(width: 8),
        _buildStatusDot(),
      ].row(alignment: MainAxisAlignment.spaceBetween),
      TaskCount(target: target),
    ].row(axisSize: MainAxisSize.max, alignment: MainAxisAlignment.spaceBetween);
  }

  Widget _buildStatusDot() {
    Color getStatusColor() {
      if (target.status == "In progress") return NotionColors.fgYellow;
      if (target.status == "Completed") return NotionColors.fgGreen;
      return NotionColors.fgBlue;
    }

    return ZStack([
      VxBox().width(5).height(5).rounded.color(getStatusColor()).make(),
      (target.status == "In progress")
          ? SizedBox(
              width: 12,
              height: 12,
              child:
                  const CircularProgressIndicator(strokeWidth: 2.5, color: NotionColors.fgYellow))
          : SizedBox(),
    ], alignment: Alignment.center);
  }
}

class TaskCount extends StatelessWidget {
  const TaskCount({Key? key, required this.target}) : super(key: key);

  final Target target;

  num get tasksPercent =>
      NaNToZero((target.taskCounts['checks']! / target.taskCounts['total']!).toDouble());

  @override
  Widget build(BuildContext context) {
    return [
      // FIXME: Use text span instead, it's cleaner and has baseline setting
      [
        '${target.checks}/${target.total}'.text.make(),
        SizedBox(width: 8),
        '${(tasksPercent * 100).round()}%'.text.size(12).make(),
      ].row(alignment: MainAxisAlignment.center, crossAlignment: CrossAxisAlignment.center),
      SizedBox(height: 2),
      RotatedBox(
        quarterTurns: 4,
        child: LinearPercentIndicator(
          width: 80,
          animation: true,
          lineHeight: 4.0,
          animationDuration: 2500,
          percent: tasksPercent.toDouble(),
          linearStrokeCap: LinearStrokeCap.roundAll,
          progressColor: Colors.green,
        ),
      ),
    ].column();
  }
}
