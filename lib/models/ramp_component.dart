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
  double _currentValue = 0.0;
  double _step = 1.0;
  double _min = 0.0;
  double _max = 100.0;
  bool _running = false;

  RampComponent({
    required String id,
  }) : super(
          id: id,
          type: ComponentType(RAMP),
        ) {
    _setupPorts();
    _startRamping();
  }

  void _setupPorts() {
    // Properties
    properties.add(Property(
      name: "Output",
      index: 0,
      isInput: false,
      type: PortType(PortType.NUMERIC),
      value: 0.0,
    ));

    properties.add(Property(
      name: "Min",
      index: 1,
      isInput: true,
      type: PortType(PortType.NUMERIC),
      value: 0.0,
    ));

    properties.add(Property(
      name: "Max",
      index: 2,
      isInput: true,
      type: PortType(PortType.NUMERIC),
      value: 100.0,
    ));

    properties.add(Property(
      name: "Step",
      index: 3,
      isInput: true,
      type: PortType(PortType.NUMERIC),
      value: 1.0,
    ));

    // Actions
    actions.add(ActionSlot(
      name: "Start",
      index: 4,
      parameterType: null,
      returnType: null,
    ));

    actions.add(ActionSlot(
      name: "Stop",
      index: 5,
      parameterType: null,
      returnType: null,
    ));

    actions.add(ActionSlot(
      name: "Reset",
      index: 6,
      parameterType: null,
      returnType: null,
    ));
  }

  @override
  void calculate() {
    _min = properties[1].value as double;
    _max = properties[2].value as double;
    _step = properties[3].value as double;

    // Apply limits
    if (_currentValue < _min) _currentValue = _min;
    if (_currentValue > _max) _currentValue = _max;

    // Update output property
    properties[0].value = _currentValue;
  }

  void _startRamping() {
    if (_running) return;

    _running = true;
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      // Random ramping
      final random = Random();
      if (random.nextBool()) {
        _currentValue += _step;
      } else {
        _currentValue -= _step;
      }

      // Apply limits
      if (_currentValue < _min) _currentValue = _min;
      if (_currentValue > _max) _currentValue = _max;

      // Update output property
      properties[0].value = _currentValue;

      // Calculate and possibly trigger any connections
      calculate();
    });
  }

  void stopRamping() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void resetRamp() {
    _currentValue = _min;
    properties[0].value = _currentValue;
    calculate();
  }

  @override
  void dispose() {
    stopRamping();
  }
}
