
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankByScoreView
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, ViewCount, Score, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByScoreView <= 10
)
SELECT 
    tr.PostId,
    tr.Title,
    tr.ViewCount,
    tr.Score,
    tr.OwnerDisplayName,
    pt.Name AS PostTypeName,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM 
    TopRankedPosts tr
JOIN 
    PostTypes pt ON pt.Id = (SELECT p.PostTypeId FROM Posts p WHERE p.Id = tr.PostId)
LEFT JOIN 
    Votes v ON v.PostId = tr.PostId
GROUP BY 
    tr.PostId, tr.Title, tr.ViewCount, tr.Score, tr.OwnerDisplayName, pt.Name
ORDER BY 
    tr.Score DESC, tr.ViewCount DESC;
