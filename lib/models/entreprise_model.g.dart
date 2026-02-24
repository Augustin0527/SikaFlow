// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'entreprise_model.dart';

class EntrepriseModelAdapter extends TypeAdapter<EntrepriseModel> {
  @override
  final int typeId = 4;

  @override
  EntrepriseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EntrepriseModel(
      id: fields[0] as String,
      nom: fields[1] as String,
      capitalDepart: fields[2] as double,
      gestionnaireId: fields[3] as String,
      dateCreation: fields[4] as DateTime,
      description: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EntrepriseModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.nom)
      ..writeByte(2)..write(obj.capitalDepart)
      ..writeByte(3)..write(obj.gestionnaireId)
      ..writeByte(4)..write(obj.dateCreation)
      ..writeByte(5)..write(obj.description);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntrepriseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
