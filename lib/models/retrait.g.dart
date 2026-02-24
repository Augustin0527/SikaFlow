// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'retrait.dart';

class RetraitAdapter extends TypeAdapter<Retrait> {
  @override
  final int typeId = 3;

  @override
  Retrait read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Retrait(
      id: fields[0] as String,
      gestionnaireId: fields[1] as String,
      agentId: fields[2] as String,
      type: fields[3] as String,
      montant: fields[4] as double,
      date: fields[5] as DateTime,
      motif: fields[6] as String?,
      ristourneId: fields[7] as String?,
      entrepriseId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Retrait obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.gestionnaireId)
      ..writeByte(2)..write(obj.agentId)
      ..writeByte(3)..write(obj.type)
      ..writeByte(4)..write(obj.montant)
      ..writeByte(5)..write(obj.date)
      ..writeByte(6)..write(obj.motif)
      ..writeByte(7)..write(obj.ristourneId)
      ..writeByte(8)..write(obj.entrepriseId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetraitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
