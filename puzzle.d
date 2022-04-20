import std.random;
import std.string;

alias StateType  = string;
alias ActionType = string;

struct Move
{
    StateType state;
    ActionType action;
}

abstract class Puzzle
{
    StateType startState;
    StateType goalState;

    this(StateType startState, StateType goalState)
    {
        this.startState = startState;
        this.goalState  = goalState;
    }

    Move[] getPossibleMoves(StateType state)
    {
        throw new Exception("Method not implemented");
    }

    Move[] getPossibleMovesReverse(StateType state)
    {
        throw new Exception("Method not implemented");
    }
}

class EightPuzzle : Puzzle
{
public:
    this()
    {
        super(randomState(GOAL_STATE), GOAL_STATE);
    }

    this(StateType startState)
    {
        super(startState, GOAL_STATE);
    }

    override Move[] getPossibleMoves(StateType state) const
    {
        return continueGetPossibleMoves(state, false);
    }

    override Move[] getPossibleMovesReverse(StateType state) const
    {
        return continueGetPossibleMoves(state, true);
    }

private:
    enum Action 
    {
        UP    = "UP",
        DOWN  = "DOWN",
        LEFT  = "LEFT",
        RIGHT = "RIGHT"
    }

    static immutable StateType GOAL_STATE = "12345678_";
    
    Move[] continueGetPossibleMoves(StateType state, bool reverse) const
    {
        Move[] moves;

        auto blankPos = state.indexOf('_');
        auto row      = blankPos / 3;
        auto col      = blankPos % 3;

        if (blankPos < 0)
            throw new Exception("Invalid state: " ~ state);

        if (row > 0)    
            moves ~= Move(state.swap(blankPos, blankPos - 3), reverse ? Action.DOWN : Action.UP);

        if (row < 2)
            moves ~= Move(state.swap(blankPos, blankPos + 3), reverse ? Action.UP : Action.DOWN);

        if (col > 0)
            moves ~= Move(state.swap(blankPos, blankPos - 1), reverse ? Action.RIGHT : Action.LEFT);

        if (col < 2)
            moves ~= Move(state.swap(blankPos, blankPos + 1), reverse ? Action.LEFT : Action.RIGHT);

        return moves;
    }

    StateType randomState(StateType seed) const
    {        
        enum NUMBER_OF_MOVES = 40;

        Move[] moves;
        auto move = Move(seed);

        foreach (i; 0..NUMBER_OF_MOVES) {
            moves = getPossibleMoves(move.state);
            move  = moves[uniform(0, moves.length)];
        }

        return move.state;
    }
}

private:
auto swap(string s, size_t i, size_t j)
{
    assert(i < s.length && j < s.length);
    auto chars = s.dup;
    std.algorithm.swap(chars[i], chars[j]);
    return cast(string) chars;
}