
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn,
        COALESCE(p.Title, 'Deleted Post') AS PostTitle
    FROM 
        PostHistory ph
    LEFT JOIN 
        Posts p ON ph.PostId = p.Id 
    WHERE 
        p.Id IS NOT NULL OR ph.PostHistoryTypeId IN (12, 13) 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 10 
)
SELECT 
    u.DisplayName,
    up.BadgeCount,
    up.BadgeNames,
    tp.Title AS PostTitle,
    tp.Score AS PostScore,
    ph.CreationDate AS HistoryDate,
    CASE 
        WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed'
        WHEN ph.PostHistoryTypeId IN (12, 13) THEN 'Deleted/Undeleted'
        ELSE 'Other Action'
    END AS PostAction,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    CASE 
        WHEN (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) > 3
            THEN 'Highly Downvoted'
        ELSE 'Normal'
    END AS VoteStatus
FROM 
    Users u
JOIN 
    UserBadges up ON u.Id = up.UserId
JOIN 
    TopPosts tp ON u.Id = tp.PostId
LEFT JOIN 
    RecursivePostHistory ph ON tp.PostId = ph.PostId AND ph.rn = 1
WHERE 
    (ph.PostHistoryTypeId IS NOT NULL AND ph.PostHistoryTypeId != 66) 
    OR (up.BadgeCount > 2 AND ph.PostId IS NULL) 
ORDER BY 
    up.BadgeCount DESC, tp.Score DESC
LIMIT 50;
