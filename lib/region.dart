class Region {
  final String identifier;
  final String uuid;
  final int? major;
  final int? minor;

  Region({
    required this.identifier,
    required this.uuid,
    this.major,
    this.minor,
  });
}
