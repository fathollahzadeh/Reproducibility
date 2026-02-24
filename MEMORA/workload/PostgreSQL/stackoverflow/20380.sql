
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation IS NULL THEN 'Unknown'
            WHEN Reputation < 1000 THEN 'Novice'
            WHEN Reputation < 5000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users
),
RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        CASE 
            WHEN ps.CommentCount > 5 THEN 'Highly Discussed'
            WHEN ps.UpvoteCount - ps.DownvoteCount > 10 THEN 'Well Received'
            ELSE 'Regular Post'
        END AS PostType
    FROM RecentPostStats ps
    WHERE ps.RecentPostRank = 1
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    ur.Reputation,
    fr.PostType,
    fr.CommentCount,
    fr.UpvoteCount,
    fr.DownvoteCount,
    ub.TotalBadges,
    ub.BadgeNames
FROM Users u
JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN FilteredPosts fr ON u.Id = fr.OwnerUserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE 
    (ur.Reputation > 2000 OR ur.Reputation IS NULL)
    AND (fr.CommentCount IS NOT NULL OR ub.TotalBadges > 0)
ORDER BY ur.Reputation DESC, fr.UpvoteCount DESC NULLS LAST;
