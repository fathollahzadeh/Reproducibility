WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(c.Score, 0) AS CommentScore,
        COALESCE(badgeCount.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) badgeCount ON p.OwnerUserId = badgeCount.UserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), 
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentScore,
        BadgeCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1
        AND Score > 10
        AND BadgeCount > 2
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    CASE 
        WHEN fp.CommentScore > 5 THEN 'Highly Commented'
        ELSE 'Less Commented'
    END AS CommentStatus,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = fp.PostId AND v.VoteTypeId = 2) AS UpvoteCount
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;