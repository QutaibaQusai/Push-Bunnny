import 'package:hive/hive.dart';
import 'package:push_bunnny/models/group_subscription_model.dart';
// Add this line at the top of the file
part 'hive_group_subscription_model.g.dart';

@HiveType(typeId: 1)
class HiveGroupSubscriptionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime subscribedAt;

  @HiveField(3)
  final bool isSynced; // Track if the subscription is synced with Firestore

  HiveGroupSubscriptionModel({
    required this.id,
    required this.name,
    required this.subscribedAt,
    this.isSynced = true, // Default is true for subscriptions from Firestore
  });

  // Create from GroupSubscriptionModel
  factory HiveGroupSubscriptionModel.fromGroupSubscriptionModel(
      GroupSubscriptionModel subscription) {
    return HiveGroupSubscriptionModel(
      id: subscription.id,
      name: subscription.name,
      subscribedAt: subscription.subscribedAt,
      isSynced: true,
    );
  }

  // Convert to GroupSubscriptionModel
  GroupSubscriptionModel toGroupSubscriptionModel() {
    return GroupSubscriptionModel(
      id: id,
      name: name,
      subscribedAt: subscribedAt,
    );
  }
}