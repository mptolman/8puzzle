import std.container;
import std.datetime;
import std.math : abs;
import std.stdio;
import std.string : indexOf;
import container;
import puzzle;

class Node
{
    StateType state;
    ActionType action;
    Node parent;
    size_t depth;
    size_t f;
    size_t g;
    size_t h;

    this(StateType state)
    {
        this.state = state;
    }

    this(StateType state, ActionType action, Node parent)
    {
        this.state  = state;
        this.action = action;
        this.parent = parent;
        this.depth  = parent.depth + 1;
    }

    this(Move move, Node parent)
    {
        this(move.state, move.action, parent);
    }
}

struct Solution
{
    Node[] solutionPath;
    size_t nodesExpanded;
    long msecs;
}

abstract class Strategy
{
public:    
    auto solve(Puzzle puzzle, out Solution solution)
    {
        Node goalNode;
        StopWatch sw;

        sw.start();
        auto result = continueSolve(puzzle, solution.nodesExpanded, goalNode);
        sw.stop();       

        solution.msecs        = sw.peek().msecs;        
        solution.solutionPath = buildSolutionPath(goalNode);

        return result == SearchResult.SUCCESS;
    }

protected:
    enum SearchResult { FAILURE, SUCCESS, CUT_OFF }

    abstract SearchResult continueSolve(Puzzle puzzle, out size_t nodesExpanded, out Node goalNode);

private:
    Node[] buildSolutionPath(Node node)
    {
        enum MAX_NODES = 50;
        Node[] path;

        foreach (i; 0..MAX_NODES) {
            if (node is null)
                break;
            path ~= node;
            node = node.parent;
        }

        return path.reverse;
    }
}

//---------------------------------------
// Breadth-First Search
//---------------------------------------
class BreadthFirstSearch : Strategy
{
protected:
    override SearchResult continueSolve(Puzzle puzzle, out size_t nodesExpanded, out Node goalNode)
    {
        Queue!Node frontier;
        Set!StateType visited;
       
        auto node = new Node(puzzle.startState);

        if (node.state == puzzle.goalState) {
            goalNode = node;
            return SearchResult.SUCCESS;
        }

        frontier.push(node);
        visited.insert(node.state);

        while (!frontier.empty) {
            node = frontier.front;
            frontier.pop();

            ++nodesExpanded;
            foreach (move; puzzle.getPossibleMoves(node.state)) {                
                auto child = new Node(move, node);

                if (!visited.contains(child.state)) {
                    if (child.state == puzzle.goalState) {
                        goalNode = child;
                        return SearchResult.SUCCESS;
                    }

                    frontier.push(child);
                    visited.insert(child.state);
                }
            }
        }

        return SearchResult.FAILURE;
    }
}

//---------------------------------------
// Depth-First Search
//---------------------------------------
class DepthFirstSearch : Strategy
{
protected:
    override SearchResult continueSolve(Puzzle puzzle, out size_t nodesExpanded, out Node goalNode)
    {
        Stack!Node frontier;
        Set!StateType visited;

        auto node = new Node(puzzle.startState);

        frontier.push(node);
        visited.insert(node.state);

        while (!frontier.empty) {
            node = frontier.top;
            frontier.pop();

            if (node.state == puzzle.goalState) {
                goalNode = node;
                return SearchResult.SUCCESS;
            }

            ++nodesExpanded;
            foreach (move; puzzle.getPossibleMoves(node.state)) {
                auto child = new Node(move, node);

                if (!visited.contains(child.state)) {
                    frontier.push(child);
                    visited.insert(child.state);
                }
            }
        }

        return SearchResult.FAILURE;
    }
}

//---------------------------------------
// Depth-Limited Search
//---------------------------------------
class DepthLimitedSearch : Strategy
{
private:
    size_t depthLimit;

public:
    this(size_t depthLimit)
    {
        this.depthLimit = depthLimit;
    }

protected:
    override SearchResult continueSolve(Puzzle puzzle, out size_t nodesExpanded, out Node goalNode)
    {
        Stack!Node frontier;
        size_t[StateType] visited;
        bool limitReached;

        auto node = new Node(puzzle.startState);

        frontier.push(node);
        visited[node.state] = node.depth;

        while (!frontier.empty) {
            node = frontier.top;
            frontier.pop();

            if (node.state == puzzle.goalState) {
                goalNode = node;
                return SearchResult.SUCCESS;
            }

            if (node.depth >= this.depthLimit) {
                limitReached = true;
                continue;
            }

            ++nodesExpanded;
            foreach (move; puzzle.getPossibleMoves(node.state)) {
                auto child = new Node(move, node);

                if (child.state !in visited || child.depth < visited[child.state]) {
                    frontier.push(child);
                    visited[child.state] = child.depth;
                }
            }
        }

        return limitReached ? SearchResult.CUT_OFF : SearchResult.FAILURE;
    }
}

//---------------------------------------
// Iterative Depth-First Search
//---------------------------------------
class IterativeDepthFirstSearch : Strategy
{
protected:
    override SearchResult continueSolve(Puzzle puzzle, out size_t nodesExpanded, out Node goalNode)
    {
        size_t totalNodesExpanded;
        auto dfs = new DepthLimitedSearch(0);

        while (true) {
            auto result = dfs.continueSolve(puzzle, nodesExpanded, goalNode);
            totalNodesExpanded += nodesExpanded;

            if (result != SearchResult.CUT_OFF)
                return result;

            ++dfs.depthLimit;
        }
    }
}

//---------------------------------------
// Bi-Directional Search
//---------------------------------------
class BiDirectionalSearch : Strategy
{
protected:
    override SearchResult continueSolve(Puzzle puzzle, out size_t nodesExpanded, out Node goalNode)
    {
        Queue!Node forwardFrontier;
        Queue!Node backwardFrontier;

        Node[StateType] forwardExplored;
        Node[StateType] backwardExplored;

        if (puzzle.startState == puzzle.goalState) {
            goalNode = new Node(puzzle.startState);
            return SearchResult.SUCCESS;
        }

        // Initialize forward frontier with initial state
        auto node = new Node(puzzle.startState);
        forwardFrontier.push(node);
        forwardExplored[node.state] = node;

        // Initialize backward frontier with goal state
        node = new Node(puzzle.goalState);
        backwardFrontier.push(node);
        backwardExplored[node.state] = node;

        while (!forwardFrontier.empty || !backwardFrontier.empty) {
            if (!forwardFrontier.empty) {
                node = forwardFrontier.front;
                forwardFrontier.pop();

                ++nodesExpanded;
                foreach (move; puzzle.getPossibleMoves(node.state)) {
                    auto child = new Node(move, node);

                    if (child.state in backwardExplored) {
                        goalNode = patch(child, backwardExplored[child.state]);
                        return SearchResult.SUCCESS;
                    }
                    else if (child.state !in forwardExplored) {
                        forwardExplored[child.state] = child;
                        forwardFrontier.push(child);
                    }
                }
            }

            if (!backwardFrontier.empty) {
                node = backwardFrontier.front;
                backwardFrontier.pop();

                ++nodesExpanded;
                foreach (move; puzzle.getPossibleMovesReverse(node.state)) {
                    auto child = new Node(move, node);

                    if (child.state in forwardExplored) {
                        goalNode = patch(forwardExplored[child.state], child);
                        return SearchResult.SUCCESS;
                    }
                    else if (child.state !in backwardExplored) {
                        backwardExplored[child.state] = child;
                        backwardFrontier.push(child);
                    }
                }
            }
        }

        return SearchResult.FAILURE;
    }

private:
    auto patch(Node forward, Node backward)
    {
        ActionType[] actions;

        // Offset actions in backward tree
        auto node = backward;
        while (node.parent !is null) {
            actions ~= node.action;
            node = node.parent;
        }

        node = backward.parent;
        foreach (action; actions) {
            node.action = action;
            node = node.parent;
        }

        // Link the trees
        auto curr = forward;
        auto next = backward.parent;
        while (next !is null) {
            auto temp = next.parent;
            next.parent = curr;
            curr = next;
            next = temp;
        }        

        return curr;
    }
}

//---------------------------------------
// Informed Search
//---------------------------------------
interface GCalculator
{
    size_t opCall(Node node);
}

interface HCalculator
{
    size_t opCall(Puzzle puzzle, Node node);
}

class EightPuzzleGCalculator : GCalculator
{
    override size_t opCall(Node node)
    {
        return node.parent.g + 1;
    }
}

class ManhattanHeuristic : HCalculator
{
    override size_t opCall(Puzzle puzzle, Node node)
    {
        size_t h;

        foreach (i,c; node.state) {
            if (c == '_') continue;

            int correctPos = puzzle.goalState.indexOf(c);
            int correctRow = correctPos / 3;
            int correctCol = correctPos % 3;

            int currentRow = i / 3;
            int currentCol = i % 3;

            h += abs(correctRow - currentRow) + abs(correctCol - currentCol);
        }

        return h;
    }
}

class RowColumnHeuristic : HCalculator
{
    override size_t opCall(Puzzle puzzle, Node node)
    {
        size_t h;

        foreach(i,c; node.state) {
            if (c == '_') continue;

            int correctPos = puzzle.goalState.indexOf(c);
            int correctRow = correctPos / 3;
            int correctCol = correctPos % 3;

            int currentRow = i / 3;
            int currentCol = i % 3;

            int rowDiff = abs(correctRow - currentRow);
            int colDiff = abs(correctCol - currentCol);

            if (rowDiff > 1 && colDiff > 1)
                h += 15;
            else if (rowDiff > 0 && colDiff > 1)
                h += 10;
            else if (rowDiff > 1 && colDiff > 0)
                h += 10;
            else if (rowDiff > 0 && colDiff > 0)
                h += 6;
            else if (rowDiff > 1 || colDiff > 1)
                h += 3;
            else if (rowDiff > 0 || colDiff > 0)
                h += 1;
        }

        return h;
    }
}

class InformedSearch : Strategy
{
private:
    GCalculator G;
    HCalculator H;

public:
    this(GCalculator G, HCalculator H)
    {
        this.G = G;
        this.H = H;
    }

protected:
    override SearchResult continueSolve(Puzzle puzzle, out size_t nodesExpanded, out Node goalNode)
    {
        BinaryHeap!(Array!Node, (a, b) => a.f > b.f) frontier;
        size_t[StateType] visited;

        auto node = new Node(puzzle.startState);

        frontier.insert(node);
        visited[node.state] = node.f;

        while (!frontier.empty) {
            node = frontier.front;
            frontier.removeFront();

            if (node.state == puzzle.goalState) {
                goalNode = node;
                return SearchResult.SUCCESS;
            }

            ++nodesExpanded;
            foreach (move; puzzle.getPossibleMoves(node.state)) {
                auto child = new Node(move, node);
                
                if (G !is null)
                    child.g = G(child);
                if (H !is null)
                    child.h = H(puzzle, child);

                child.f = child.g + child.h;

                if (child.state !in visited || child.f < visited[child.state]) {
                    frontier.insert(child);
                    visited[child.state] = child.f;
                }
            }
        }

        return SearchResult.FAILURE;
    }
}