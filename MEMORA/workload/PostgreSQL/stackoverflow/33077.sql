WITH RecursiveBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeTotal,
        MAX(Date) AS LastBadgeDate
    FROM 
        Badges
    GROUP BY 
        UserId
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(bc.BadgeTotal, 0) AS TotalBadges,
        COALESCE(np.RecentPostCount, 0) AS RecentPostCount,
        COALESCE(AP.RecentAcceptedCount, 0) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        RecursiveBadgeCounts bc ON u.Id = bc.UserId
    LEFT JOIN (
        SELECT
            OwnerUserId,
            COUNT(*) AS RecentPostCount
        FROM
            RecentPosts
        GROUP BY
            OwnerUserId
    ) np ON u.Id = np.OwnerUserId
    LEFT JOIN (
        SELECT
            p.OwnerUserId,
            COUNT(*) AS RecentAcceptedCount
        FROM
            Posts p
        WHERE
            AcceptedAnswerId IS NOT NULL AND CreationDate > cast('2024-10-01' as date) - INTERVAL '90 days'
        GROUP BY
            p.OwnerUserId
    ) AP ON u.Id = AP.OwnerUserId
),
PostVoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalBadges, 
    us.RecentPostCount,
    us.AcceptedAnswers,
    pp.Title,
    pp.Score,
    ps.VoteCount,
    ps.Upvotes,
    ps.Downvotes,
    CASE 
        WHEN ps.VoteCount = 0 THEN 'No Votes'
        WHEN ps.Upvotes > ps.Downvotes THEN 'Positive Engagement'
        ELSE 'Negative Engagement'
    END AS EngagementLevel
FROM 
    UserStatistics us
LEFT JOIN 
    RecentPosts pp ON us.UserId = pp.OwnerUserId AND pp.RecentPostRank = 1
LEFT JOIN 
    PostVoteStatistics ps ON pp.Id = ps.PostId
WHERE 
    us.TotalBadges > 0 OR us.RecentPostCount > 0
ORDER BY 
    us.TotalBadges DESC, 
    us.RecentPostCount DESC;