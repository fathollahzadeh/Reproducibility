WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties,
        MAX(u.CreationDate) AS AccountCreationDate,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        COALESCE(pv.VoteCount, 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) pv ON p.Id = pv.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.TotalBounties,
    rp.Title,
    rp.CreationDate,
    rp.VoteCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    CASE 
        WHEN rp.RecentRank = 1 THEN 'Recent Post'
        WHEN rp.RecentRank <= 5 THEN 'Recently Active'
        ELSE 'Older Activity'
    END AS ActivityType,
    COALESCE(ph.Comment, 'No Comments') AS LastEditComment
FROM 
    UserActivity ua
JOIN 
    RecentPosts rp ON ua.UserId = rp.OwnerUserId
LEFT OUTER JOIN 
    PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) 
WHERE 
    ua.PostCount > 0
    AND (ua.TotalBounties IS NULL OR ua.TotalBounties > 0)
ORDER BY 
    ua.TotalBounties DESC, 
    rp.CreationDate DESC;