

begin=0
end=145

items=[]
for i in range(begin, end+1):
    items.append(f"({i},0.1)")

ff = " ".join(items)
print("{"+(" ".join(items))+"}")