
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, Title, ViewCount, CreationDate, Score, OwnerName, CommentCount, VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.ViewCount,
    t.CreationDate,
    t.Score,
    t.OwnerName,
    t.CommentCount,
    t.VoteCount,
    COALESCE(b.BadgesCount, 0) AS BadgeCount
FROM 
    TopPosts t
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgesCount
     FROM Badges
     GROUP BY UserId) b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = t.PostId LIMIT 1)
ORDER BY 
    t.Score DESC;
