import std.container;

struct Stack(T)
{
private:
    DList!T dlist;

public:
    auto push(T t)
    {
        dlist.stableInsertFront(t);
    }

    auto pop()
    {
        dlist.stableRemoveFront();
    }

    auto top()
    {
        return dlist.front();
    }

    auto empty() const
    {
        return dlist.empty();
    }

    auto clear()
    {
        dlist.clear();
    }
}

struct Queue(T)
{
private:
    DList!T dlist;

public:
    auto push(T t)
    {
        dlist.stableInsertBack(t);
    }

    auto pop()
    {
        dlist.stableRemoveFront();
    }

    auto front()
    {
        return dlist.front();
    }

    auto empty() const
    {
        return dlist.empty();
    }

    auto clear()
    {
        dlist.clear();
    }
}

struct Set(T)
{
private:
    byte[T] data;

public:
    auto contains(T t) const
    {
        return t in data;
    }

    auto insert(T t)
    {
        data[t] = 1;
    }

    auto remove(T t)
    {
        data.remove(t);
    }

    auto size() const
    {
        return data.length;
    }

    auto clear()
    {
        data = null;
    }
}