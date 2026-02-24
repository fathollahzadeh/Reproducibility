WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerCheck
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Score > 0 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.CreationDate AS CloseDate,
        COUNT(*) AS CloseVoteCount,
        MAX(ph.PostHistoryTypeId) AS LatestCloseAction
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        p.Id, ph.CreationDate
)
SELECT 
    up.PostId,
    up.Title,
    ub.UserId,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    cp.CloseVoteCount,
    cp.LatestCloseAction,
    CASE
        WHEN up.AcceptedAnswerCheck != -1 THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptanceStatus
FROM 
    RankedPosts up
JOIN 
    UserBadges ub ON up.OwnerUserId = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON up.PostId = cp.ClosedPostId
WHERE 
    (up.PostRank = 1 AND up.CommentCount > 5) OR
    (up.CommentCount = 0 AND ub.BadgeCount > 3)
ORDER BY 
    up.Score DESC,
    cp.CloseVoteCount DESC NULLS LAST
LIMIT 100;