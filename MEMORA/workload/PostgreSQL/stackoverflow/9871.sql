
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    t.Title,
    t.OwnerDisplayName,
    t.Score,
    t.ViewCount,
    t.CommentCount,
    COALESCE(SUM(b.Class), 0) AS TotalBadges
FROM 
    TopPosts t
LEFT JOIN 
    Badges b ON t.OwnerDisplayName = CAST(b.UserId AS VARCHAR)
GROUP BY 
    t.PostId, t.Title, t.OwnerDisplayName, t.Score, t.ViewCount, t.CommentCount
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
