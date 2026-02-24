
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
PostStatistics AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        CASE 
            WHEN r.Score > 100 THEN 'Hot'
            WHEN r.Score BETWEEN 50 AND 100 THEN 'Trending'
            ELSE 'Normal'
        END AS PostStatus
    FROM 
        RankedPosts r
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges 
        WHERE 
            Class = 1
        GROUP BY 
            UserId
    ) AS b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = r.PostId)
)
SELECT 
    p.Title,
    p.PostStatus,
    p.CommentCount,
    p.Score,
    COALESCE(ut.DisplayName, 'Anonymous') AS OwnerDisplayName,
    p.CreationDate,
    (SELECT 
         COUNT(*) 
     FROM 
         Votes v 
     WHERE 
         v.PostId = p.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
    (SELECT 
         COUNT(*) 
     FROM 
         Votes v 
     WHERE 
         v.PostId = p.PostId AND v.VoteTypeId = 3) AS DownvoteCount
FROM 
    PostStatistics p
LEFT JOIN 
    Users ut ON ut.Id = (SELECT OwnerUserId FROM Posts WHERE Id = p.PostId)
WHERE 
    p.CommentCount > 5 
    AND p.BadgeCount > 0
ORDER BY 
    p.Score DESC 
LIMIT 10;
