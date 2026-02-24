WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Location,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation < 100 THEN 'Newbie'
            WHEN u.Reputation >= 100 AND u.Reputation < 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM 
        Users u
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Badges b
    WHERE 
        b.Class IN (1, 2) 
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    ur.Location,
    ur.ReputationLevel,
    COALESCE(cb.CloseCount, 0) AS TotalCloseCount,
    COALESCE(cb.CloseReasons, 'No close reasons') AS CloseReasons,
    ub.BadgeCount AS TotalBadges,
    CASE 
        WHEN ur.ReputationLevel = 'Expert' AND COALESCE(ub.BadgeCount, 0) > 5 THEN 'Super Expert'
        ELSE ur.ReputationLevel
    END AS FinalReputationLevel,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS Upvotes
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    ClosedPosts cb ON rp.PostId = cb.PostId
LEFT JOIN 
    UserBadges ub ON ur.UserId = ub.UserId
WHERE 
    rp.Rank = 1 
    AND rp.PostTypeId = 1 
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;