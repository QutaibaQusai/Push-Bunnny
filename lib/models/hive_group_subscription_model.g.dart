// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_group_subscription_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveGroupSubscriptionModelAdapter
    extends TypeAdapter<HiveGroupSubscriptionModel> {
  @override
  final int typeId = 1;

  @override
  HiveGroupSubscriptionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveGroupSubscriptionModel(
      id: fields[0] as String,
      name: fields[1] as String,
      subscribedAt: fields[2] as DateTime,
      isSynced: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveGroupSubscriptionModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.subscribedAt)
      ..writeByte(3)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveGroupSubscriptionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
