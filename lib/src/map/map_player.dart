import 'package:bot/bot.dart' hide ReadOnlyCollection;

class MapPlayer extends Comparable<MapPlayer> {
  static int _counter = 0;

  final int _id;
  final String name;
  Coordinate _location;

  MapPlayer(this._location, [this.name = null]) : _id = _counter++;

  Coordinate get location => _location;

  void set location(Coordinate value) {
    requireArgumentNotNull(value, 'value');
    _location = value;
  }

  int get id => _id;

  @override
  int compareTo(MapPlayer other) => _id.compareTo(other._id);

  @override
  int get hashCode => _id.hashCode;

  @override
  bool operator ==(MapPlayer other) => other != null && other._id == _id;

  @override
  String toString() {
    if (name == null) {
      return "MapPlayer at [${_location.x.toStringAsFixed(1)}, ${_location.y.toStringAsFixed(1)}]";
    } else {
      return name;
    }
  }
}
