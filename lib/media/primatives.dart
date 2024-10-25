
/// Metadata to be used in the cache
///
class Meta {
  String name;
  String extension;
  DateTime created;
  DateTime modified;
  String path;

  Meta(this.name, this.extension, this.created, this.modified, this.path);

  Map toJson() => {
        'name': name,
        'extension': extension,
        'created': created.toIso8601String(),
        'modified': modified.toIso8601String(),
        'path': path
      };

  Meta.fromJson(Map<String, dynamic> json)
      : this(json['name'], json['extension'], DateTime.parse(json['created']),
            DateTime.parse(json['modified']), json['path']);
}

