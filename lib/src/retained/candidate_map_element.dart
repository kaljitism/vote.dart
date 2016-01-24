import 'package:bot/bot.dart' hide ReadOnlyCollection;
import 'package:bot_web/bot_retained.dart';
import 'package:vote/map.dart';

import 'candidate_element.dart';
import 'map_element_base.dart';
import 'root_map_element.dart';

class CandidateMapElement extends ParentThing implements MapElementBase {
  final List<MapPlayer> _players = new List<MapPlayer>();
  final AffineTransform _tx = new AffineTransform();

  num radius = 0;
  List<CandidateElement> _elements;
  List<MapPlayer> _showOnlyPlayers = null;

  CandidateMapElement(int w, int h) : super(w, h);

  int get visualChildCount {
    _ensureElements();
    return _elements.length;
  }

  Thing getVisualChild(int index) {
    _ensureElements();
    return _elements[index];
  }

  void setTransform(AffineTransform value) {
    requireArgumentNotNull(value, 'value');
    _tx.setFromTransfrom(value);
    invalidateDraw();
  }

  Iterable<MapPlayer> get players => _players;

  void set players(Iterable<MapPlayer> value) {
    requireArgumentNotNull(value, "value");
    _players.clear();
    _players.addAll(value);
    _elements = null;
    invalidateDraw();
  }

  List<MapPlayer> get showOnlyPlayers => _showOnlyPlayers;

  void set showOnlyPlayers(Iterable<MapPlayer> value) {
    if (value == null) {
      _showOnlyPlayers = null;
    } else {
      var newVal = new List.unmodifiable(value);
      assert($(newVal).distinct().length == newVal.length);
      assert(newVal.every((e) => _players.indexOf(e) >= 0));
      _showOnlyPlayers = newVal;
    }

    if (_elements == null) {
      invalidateDraw();
    } else {
      _updateCandidateElements();
    }
  }

  void _ensureElements() {
    if (_elements == null) {
      _elements = new List<CandidateElement>();
      for (final p in _players) {
        final hue = LocationData.getHue(p);
        final rgb = (new HslColor(hue, 0.5, 0.6)).toRgb();
        final ce = new CandidateElement(radius * 4, radius * 4, rgb.toHex(), p);
        ce.registerParent(this);

        MouseManager.setCursor(ce, 'pointer');
        MouseManager.setDraggable(ce, true);
        MouseManager.getDragStream(ce).listen(_candidateDragged);

        final tempTx = ce.addTransform();
        tempTx.concatenate(_tx);
        tempTx.translate(p.location.x - 2 * radius, p.location.y - 2 * radius);

        _elements.add(ce);
      }
      _updateCandidateElements();
    }
  }

  void _candidateDragged(ThingDragEventArgs e) {
    final RootMapElement rme = parent;
    final CandidateElement ce = e.thing;
    final player = ce.player;

    rme.dragCandidate(player, e.delta);
  }

  void _updateCandidateElements() {
    assert(_elements != null);
    for (final e in _elements) {
      e.hidden =
          _showOnlyPlayers != null && _showOnlyPlayers.indexOf(e.player) < 0;
    }
  }
}
