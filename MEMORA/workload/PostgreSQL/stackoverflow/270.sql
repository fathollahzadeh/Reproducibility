
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        ViewCount,
        RankScore
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    u.DisplayName AS UserName,
    u.Reputation
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.PostId IN (SELECT ParentId FROM Posts WHERE AcceptedAnswerId = tp.PostId)
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    u.Reputation > 1000
UNION ALL
SELECT 
    'Highest Scoring Post' AS Title,
    MAX(p.Score) AS Score,
    NULL AS ViewCount,
    'N/A' AS BadgeName,
    'SYSTEM' AS UserName,
    NULL AS Reputation
FROM 
    Posts p
WHERE 
    p.Score IS NOT NULL 
GROUP BY 
    p.Score
HAVING 
    MAX(p.Score) > 100
ORDER BY 
    Score DESC;
