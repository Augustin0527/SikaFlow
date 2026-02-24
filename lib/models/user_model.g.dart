// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'user_model.dart';

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      nom: fields[1] as String,
      prenom: fields[2] as String,
      telephone: fields[3] as String,
      motDePasse: fields[4] as String,
      role: fields[5] as String,
      gestionnaireId: fields[6] as String?,
      dateCreation: fields[7] as DateTime,
      actif: fields[8] as bool,
      email: fields[9] as String?,
      entrepriseId: fields[10] as String?,
      motDePasseProvisoire: fields[11] as bool,
      controleurAssigneId: fields[12] as String?,
      agentsAssignesIds: (fields[13] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.nom)
      ..writeByte(2)..write(obj.prenom)
      ..writeByte(3)..write(obj.telephone)
      ..writeByte(4)..write(obj.motDePasse)
      ..writeByte(5)..write(obj.role)
      ..writeByte(6)..write(obj.gestionnaireId)
      ..writeByte(7)..write(obj.dateCreation)
      ..writeByte(8)..write(obj.actif)
      ..writeByte(9)..write(obj.email)
      ..writeByte(10)..write(obj.entrepriseId)
      ..writeByte(11)..write(obj.motDePasseProvisoire)
      ..writeByte(12)..write(obj.controleurAssigneId)
      ..writeByte(13)..write(obj.agentsAssignesIds);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
