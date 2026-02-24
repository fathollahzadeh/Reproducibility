
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score IS NOT NULL 
        AND p.ViewCount > 0
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COALESCE(AVG(p.ViewCount), 0) AS AvgViewsPerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
UserBadges AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
HighScoringPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.ViewCount,
        CASE 
            WHEN cp.PostId IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.PostRank <= 10
)

SELECT 
    u.DisplayName,
    u.Reputation,
    ups.TotalPosts,
    ups.TotalUpvotes,
    ups.TotalDownvotes,
    ups.AvgViewsPerPost,
    hb.BadgeCount,
    hb.BadgeNames,
    hsp.PostId,
    hsp.Title,
    hsp.ViewCount,
    hsp.PostStatus
FROM 
    Users u
JOIN 
    UserPostStats ups ON u.Id = ups.UserId
LEFT JOIN 
    UserBadges hb ON u.Id = hb.UserId
JOIN 
    HighScoringPosts hsp ON hsp.PostStatus = 'Active'
WHERE 
    u.Location IS NOT NULL 
    AND u.Reputation BETWEEN 100 AND 1000
    AND NOT EXISTS (
        SELECT 1 
        FROM Posts p
        WHERE p.OwnerUserId = u.Id AND p.ViewCount < 5
    )
ORDER BY 
    u.Reputation DESC, 
    hsp.ViewCount DESC;
