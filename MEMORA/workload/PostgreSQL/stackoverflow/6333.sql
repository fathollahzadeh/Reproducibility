
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount, p.PostTypeId
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        OwnerDisplayName, 
        Score, 
        ViewCount, 
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 5
),
PostsWithBadges AS (
    SELECT 
        tr.PostId, 
        tr.Title, 
        tr.CreationDate, 
        tr.OwnerDisplayName, 
        tr.Score, 
        tr.ViewCount, 
        tr.CommentCount, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        TopRankedPosts tr
    LEFT JOIN 
        Badges b ON tr.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
    GROUP BY 
        tr.PostId, tr.Title, tr.CreationDate, tr.OwnerDisplayName, tr.Score, tr.ViewCount, tr.CommentCount
)
SELECT 
    p.PostId, 
    p.Title, 
    p.CreationDate, 
    p.OwnerDisplayName, 
    p.Score, 
    p.ViewCount, 
    p.CommentCount, 
    p.BadgeCount,
    STRING_AGG(pt.Name, ', ') AS PostTypeNames
FROM 
    PostsWithBadges p
JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = p.PostId)
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.OwnerDisplayName, p.Score, p.ViewCount, p.CommentCount, p.BadgeCount
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC;
