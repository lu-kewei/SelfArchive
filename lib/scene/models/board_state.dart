import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/camera/camera_state.dart';
import '../../core/theme/theme_pack.dart';
import 'node_entity.dart';
import 'edge_entity.dart';

part 'board_state.freezed.dart';

@freezed
class BoardState with _$BoardState {
  const factory BoardState({
    @Default([]) List<NodeEntity> nodes,
    @Default([]) List<EdgeEntity> edges,
    required CameraState camera,
    required ThemePack theme,
    @Default(2080.0) double boardWidth,
    @Default(1240.0) double boardHeight,
    @Default(false) bool isLoading,
    @Default(false) bool isResizing, // Board resize mode
    String? selectedNodeId,
    AnchorRef? selectedPin, // Selected pin for connection
  }) = _BoardState;
}
