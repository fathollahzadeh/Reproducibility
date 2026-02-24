
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    pb.BadgeCount,
    COALESCE(pb.BadgeNames, 'No badges') AS BadgeNames,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRankCategory,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) THEN 'Has Upvotes'
        ELSE 'No Upvotes'
    END AS UpvoteStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostBadges pb ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = pb.UserId)
WHERE 
    COALESCE(rp.ViewCount, 0) > 100
ORDER BY 
    rp.Score DESC, rp.CommentCount DESC
LIMIT 100;
