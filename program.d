import std.process;
import std.stdio;
import std.string;
import puzzle;
import search;

private:
Puzzle thePuzzle;

public:
auto mainMenu()
{
    Menu:
    while (true) {
        version(Windows) system("cls");
        version(linux) system("clear");

        writeln("  ----------------------------");
        writeln("  Main Menu");
        writeln("  ----------------------------");
        writeln("  1 - Load puzzle from file");
        writeln("  2 - Generate random puzzle");
        writeln("  3 - Solve current puzzle");
        writeln;
        writeln("  0 - Exit");
        writeln;

        write("  Current puzzle: ");
        if (.thePuzzle is null)
            writeln("No puzzle loaded");
        else
            writefln("\n%s", formattedState(.thePuzzle.startState));
        writeln;

        switch(getMenuSelection()) {
        case '1':
            loadPuzzleFromFile();
            break;
        case '2':
            .thePuzzle = new EightPuzzle;        
            break;
        case '3':
            if (.thePuzzle !is null) {
                auto exit = algorithmMenu();
                if (exit)
                    break Menu;
            }
            break;
        case '0':
            break Menu;
        default:
            break;
        }
    }
}

auto algorithmMenu()
{
    bool exit;

    auto getDepthLimit()
    {
        size_t depthLimit;

        while (true) {
            write("Enter depth limit: ");
            try {
                readf(" %d", &depthLimit);
                break;
            }
            catch (Exception e) {
                writeln("Invalid number.");
                stdin.flush;
            }
        }

        return depthLimit;
    }

    Menu:
    while (true) {
        version(Windows) system("cls");
        version(Linux) system("clear");

        writeln("  ----------------------------");
        writeln("  Select an algorithm");
        writeln("  ----------------------------");
        writeln("  1 - Breadth-First Search");
        writeln("  2 - Depth-First Search");
        writeln("  3 - Depth-Limited Search");
        writeln("  4 - Iterative Deepening Search");
        writeln("  5 - Bi-Directional Search");
        writeln("  6 - Greedy Best-First Search (Manhattan)");
        writeln("  7 - A* (Manhattan)");
        writeln("  8 - A* (Row/Column)");
        writeln;
        writeln("  m - Main Menu");
        writeln("  0 - Exit");
        writeln;

        switch (getMenuSelection()) {
        case '1':
            solve(new BreadthFirstSearch);
            break;
        case '2':
            solve(new DepthFirstSearch);
            break;
        case '3':
            solve(new DepthLimitedSearch(getDepthLimit()));
            break;
        case '4':
            solve(new IterativeDepthFirstSearch);
            break;
        case '5':
            solve(new BiDirectionalSearch);
            break;
        case '6':
            solve(new InformedSearch(null, new ManhattanHeuristic));
            break;
        case '7':
            solve(new InformedSearch(new EightPuzzleGCalculator, new ManhattanHeuristic));
            break;
        case '8':
            solve(new InformedSearch(new EightPuzzleGCalculator, new RowColumnHeuristic));
            break;
        case 'm':
        case 'M':
            break Menu;
        case '0':
            exit = true;
            break Menu;
        default:
            break;
        }
    }

    return exit;
}

auto solve(Strategy strategy)
{
    Solution solution;

    if (strategy.solve(.thePuzzle, solution)) {
        writeln("Initial state:");
        writeln(formattedState(.thePuzzle.startState));
        writeln;

        writeln("Solution path:");
        foreach (node; solution.solutionPath[1..$])
            writef("Move %s:\n%s\n\n", node.action, formattedState(node.state));

        writefln("Search Time (ms): %d", solution.msecs);
        writefln("Nodes Expanded: %d", solution.nodesExpanded);
    }
    else {
        writeln("No solution found!");
    }

    write("\nPress <Enter> to return to menu");
    stdin.flush();
    readln();
}

auto getMenuSelection()
{
    char sel;
    write("> ");
    readf(" %c", &sel);
    stdin.flush();
    return sel;
}

auto loadPuzzleFromFile()
{
    StateType state;
    string fileName;

    while (true) {
        try {
            write("Enter file name: ");
            readf(" %s\n", &fileName);

            auto file = File(fileName);
            foreach (line; file.byLine())
                state ~= strip(line);
            .thePuzzle = new EightPuzzle(state);
            break;
        }
        catch (Exception e) {
            writeln("Invalid file.");
        }
    }
}

auto formattedState(StateType state)
{
    StateType prettyState;

    foreach (i,c; state) {
        if (i % 3 == 0)
            prettyState ~= "  ";

        prettyState ~= [c, ' '];
        
        if ((i + 1) % 3 == 0)
            prettyState ~= '\n';
    }

    return stripRight(prettyState);
}