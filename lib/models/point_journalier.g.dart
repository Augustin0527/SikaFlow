// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'point_journalier.dart';

class PointJournalierAdapter extends TypeAdapter<PointJournalier> {
  @override
  final int typeId = 1;

  @override
  PointJournalier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PointJournalier(
      id: fields[0] as String,
      agentId: fields[1] as String,
      gestionnaireId: fields[2] as String,
      date: fields[3] as DateTime,
      montantEspeces: fields[4] as double,
      soldeMTN: fields[5] as double,
      soldeMoov: fields[6] as double,
      soldeCeltiis: fields[7] as double,
      observations: fields[8] as String?,
      valide: fields[9] as bool,
      validateurId: fields[10] as String?,
      dateValidation: fields[11] as DateTime?,
      entrepriseId: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PointJournalier obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.agentId)
      ..writeByte(2)..write(obj.gestionnaireId)
      ..writeByte(3)..write(obj.date)
      ..writeByte(4)..write(obj.montantEspeces)
      ..writeByte(5)..write(obj.soldeMTN)
      ..writeByte(6)..write(obj.soldeMoov)
      ..writeByte(7)..write(obj.soldeCeltiis)
      ..writeByte(8)..write(obj.observations)
      ..writeByte(9)..write(obj.valide)
      ..writeByte(10)..write(obj.validateurId)
      ..writeByte(11)..write(obj.dateValidation)
      ..writeByte(12)..write(obj.entrepriseId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointJournalierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
