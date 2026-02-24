
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) AS TotalVotes,
        COALESCE(AVG(c.Score), 0) AS AvgCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.RankScore,
        rp.TotalVotes,
        rp.AvgCommentScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10
)

SELECT 
    up.DisplayName AS UserName,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate,
    tp.TotalVotes,
    tp.AvgCommentScore,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    TopPosts tp
LEFT JOIN 
    Users up ON tp.PostId = up.Id
LEFT JOIN 
    Badges b ON up.Id = b.UserId AND b.Class = 1 
ORDER BY 
    tp.CreationDate DESC
LIMIT 50;
