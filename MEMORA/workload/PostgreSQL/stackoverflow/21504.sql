
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN b.UserId IS NOT NULL THEN b.UserId END) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        p.Id, p.OwnerUserId
),
PostHistoryRecent AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
),
FilteredBadges AS (
    SELECT 
        UserId,
        MAX(Class) AS HighestBadgeClass
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    u.DisplayName,
    ps.PostId,
    ps.Upvotes,
    ps.Downvotes,
    ps.CommentCount,
    PS2.RecentEditUser,
    PS2.EditDate,
    COALESCE(fb.HighestBadgeClass, 0) AS BadgeClass,
    CASE 
        WHEN ps.Upvotes - ps.Downvotes > 0 THEN 'Popular'
        ELSE 'Unpopular'
    END AS Popularity
FROM 
    Users u
JOIN 
    PostStatistics ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    (SELECT 
        ph.PostId,
        ph.UserDisplayName AS RecentEditUser,
        ph.CreationDate AS EditDate
     FROM 
        PostHistoryRecent ph
     WHERE 
        ph.RecentEditRank = 1) PS2 ON ps.PostId = PS2.PostId
LEFT JOIN 
    FilteredBadges fb ON u.Id = fb.UserId
WHERE 
    (
        SELECT COUNT(*) 
        FROM Posts p 
        WHERE p.OwnerUserId = u.Id
    ) > 10 
AND 
    (ps.Upvotes > 10 OR ps.CommentCount > 5)
ORDER BY 
    ps.PostId;
