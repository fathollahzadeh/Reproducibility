
WITH BenchmarkData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        pt.Name AS PostTypeName,
        bh.CreationDate AS HistoryDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        PostHistory bh ON p.Id = bh.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, u.Reputation, pt.Name, bh.CreationDate
)

SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    OwnerReputation,
    CommentCount,
    VoteCount,
    PostTypeName,
    HistoryDate,
    COUNT(*) OVER() AS TotalRows
FROM 
    BenchmarkData
ORDER BY 
    ViewCount DESC 
FETCH FIRST 100 ROWS ONLY;
