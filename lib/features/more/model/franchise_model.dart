class FranchiseOutlet {
  final String id;
  final String name;
  final String refId;
  final bool isLocked;

  FranchiseOutlet({
    required this.id,
    required this.name,
    required this.refId,
    this.isLocked = false,
  });
}
