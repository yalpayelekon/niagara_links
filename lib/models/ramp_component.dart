// ramp_component.dart
import 'dart:async';
import 'dart:math';
import 'component.dart';
import 'component_type.dart';
import 'port.dart';
import 'port_type.dart';

class RampComponent extends Component {
  static const String RAMP = "RAMP";

  Timer? _timer;
  double _stepAmount = 0.0;
  final double _stepRange = 10.0;
  final double _min = 0.0;
  final double _max = 100.0;
  bool _running = false;

  RampComponent({
    required super.id,
  }) : super(
          type: ComponentType(RAMP),
        ) {
    _setupPorts();
    _startRamping();
  }

  void _setupPorts() {
    properties.add(Property(
      name: "Output",
      index: 0,
      isInput: false,
      type: PortType(PortType.NUMERIC),
      value: 0.0,
    ));
  }

  @override
  void calculate() {
    properties[0].value += properties[0].value + _stepAmount;
    if (properties[0].value >= _max) {
      properties[0].value = _min;
    }
  }

  void _startRamping() {
    if (_running) return;

    _running = true;
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      final random = Random();
      _stepAmount = random.nextDouble() * _stepRange;
      calculate();
    });
  }

  void stopRamping() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stopRamping();
  }
}
