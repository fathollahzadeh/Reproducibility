WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE((
            SELECT COUNT(v.Id) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2
        ), 0) AS UpvoteCount,
        COALESCE((SELECT COUNT(*) 
            FROM PostHistory ph 
            WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 10), 0) AS CloseCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
), 
RecentBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b 
    WHERE 
        b.Date >= (cast('2024-10-01' as date) - INTERVAL '1 month')
    GROUP BY 
        b.UserId
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(rb.BadgeNames, 'No Badges') AS Badges,
        CASE 
            WHEN u.Reputation < 1000 THEN 'Newbie'
            WHEN u.Reputation BETWEEN 1000 AND 5000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS UserLevel
    FROM 
        Users u 
    LEFT JOIN 
        RecentBadges rb ON u.Id = rb.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.Badges,
    us.UserLevel,
    rp.Score,
    rp.UpvoteCount,
    rp.CommentCount,
    CASE 
        WHEN rp.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    rp.ViewCount,
    ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS PopularityRank
FROM 
    RankedPosts rp 
JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
WHERE 
    (rp.PostTypeId = 1 AND rp.RowNum <= 5) 
    OR (rp.PostTypeId = 2 AND rp.UpvoteCount > 10)
ORDER BY 
    rp.CreationDate DESC;