// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_notification_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveNotificationModelAdapter extends TypeAdapter<HiveNotificationModel> {
  @override
  final int typeId = 0;

  @override
  HiveNotificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveNotificationModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      body: fields[3] as String,
      timestamp: fields[4] as DateTime,
      imageUrl: fields[5] as String?,
      groupId: fields[6] as String?,
      groupName: fields[7] as String?,
      isRead: fields[8] as bool,
      readAt: fields[9] as DateTime?,
      isSynced: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveNotificationModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.body)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.groupId)
      ..writeByte(7)
      ..write(obj.groupName)
      ..writeByte(8)
      ..write(obj.isRead)
      ..writeByte(9)
      ..write(obj.readAt)
      ..writeByte(10)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveNotificationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
