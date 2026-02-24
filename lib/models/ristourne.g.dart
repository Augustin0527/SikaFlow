// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'ristourne.dart';

class RistourneAdapter extends TypeAdapter<Ristourne> {
  @override
  final int typeId = 2;

  @override
  Ristourne read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ristourne(
      id: fields[0] as String,
      agentId: fields[1] as String,
      gestionnaireId: fields[2] as String,
      operateur: fields[3] as String,
      montant: fields[4] as double,
      date: fields[5] as DateTime,
      controleurId: fields[6] as String,
      observations: fields[7] as String?,
      retiree: fields[8] as bool,
      dateRetrait: fields[9] as DateTime?,
      retireePar: fields[10] as String?,
      entrepriseId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Ristourne obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.agentId)
      ..writeByte(2)..write(obj.gestionnaireId)
      ..writeByte(3)..write(obj.operateur)
      ..writeByte(4)..write(obj.montant)
      ..writeByte(5)..write(obj.date)
      ..writeByte(6)..write(obj.controleurId)
      ..writeByte(7)..write(obj.observations)
      ..writeByte(8)..write(obj.retiree)
      ..writeByte(9)..write(obj.dateRetrait)
      ..writeByte(10)..write(obj.retireePar)
      ..writeByte(11)..write(obj.entrepriseId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RistourneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
