class_name VictoryRules
extends RefCounted


static func evaluate(position: ChessPosition, waters: Array[float], round_number: int, final_round: int) -> Verdict:
	var chess := chess_verdict(position)
	if chess.is_finished():
		return chess
	var water := water_verdict(waters)
	if water.is_finished():
		return water
	if round_number >= final_round:
		return final_verdict(position, waters)
	return Verdict.new()


static func chess_verdict(position: ChessPosition) -> Verdict:
	match MovementValidator.status(position):
		MovementValidator.Status.CHECKMATE:
			return Verdict.new(Verdict.Reason.CHECKMATE, MovementValidator.winner(position))
		MovementValidator.Status.KING_LOST:
			return Verdict.new(Verdict.Reason.KING_LOST, MovementValidator.winner(position))
		MovementValidator.Status.STALEMATE:
			return Verdict.new(Verdict.Reason.STALEMATE)
	return Verdict.new()


static func water_verdict(waters: Array[float]) -> Verdict:
	var player_dry := waters[ChessPosition.PLAYER] <= 0.0
	var rival_dry := waters[ChessPosition.RIVAL] <= 0.0
	if player_dry and rival_dry:
		return Verdict.new(Verdict.Reason.BOTH_COLLAPSED)
	if player_dry:
		return Verdict.new(Verdict.Reason.WATER_COLLAPSE, ChessPosition.RIVAL)
	if rival_dry:
		return Verdict.new(Verdict.Reason.WATER_COLLAPSE, ChessPosition.PLAYER)
	return Verdict.new()


static func final_verdict(position: ChessPosition, waters: Array[float]) -> Verdict:
	var leader := _leader(waters[ChessPosition.PLAYER], waters[ChessPosition.RIVAL])
	if leader != Verdict.NO_WINNER:
		return Verdict.new(Verdict.Reason.FINAL_WATER, leader)
	leader = _leader(position.material(ChessPosition.PLAYER), position.material(ChessPosition.RIVAL))
	if leader != Verdict.NO_WINNER:
		return Verdict.new(Verdict.Reason.FINAL_MATERIAL, leader)
	return Verdict.new(Verdict.Reason.FINAL_DRAW)


static func _leader(player_score: float, rival_score: float) -> int:
	if is_equal_approx(player_score, rival_score):
		return Verdict.NO_WINNER
	return ChessPosition.PLAYER if player_score > rival_score else ChessPosition.RIVAL
