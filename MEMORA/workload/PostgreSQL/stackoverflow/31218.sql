
WITH RECURSIVE UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        AVG(p.Score) AS AvgPostScore,
        MAX(p.LastActivityDate) AS LastActiveDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserStatistics AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.Reputation,
        ue.TotalPosts,
        ue.TotalAnswers,
        ue.TotalBounty,
        rpa.TotalComments,
        rpa.AvgPostScore,
        rpa.LastActiveDate,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        UserEngagement ue
    LEFT JOIN 
        RecentPostActivity rpa ON ue.UserId = rpa.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON ue.UserId = ub.UserId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts, 
    us.TotalAnswers, 
    us.TotalBounty,
    COALESCE(us.TotalComments, 0) AS TotalComments,
    COALESCE(us.AvgPostScore, 0) AS AvgPostScore,
    us.LastActiveDate,
    COALESCE(us.BadgeCount, 0) AS BadgeCount,
    COALESCE(us.BadgeNames, 'No Badges') AS BadgeNames
FROM 
    UserStatistics us
WHERE 
    us.Reputation > 1000 
    AND (us.TotalPosts > 10 OR us.TotalAnswers > 5)
ORDER BY 
    us.Reputation DESC,
    us.TotalPosts DESC
FETCH FIRST 50 ROWS ONLY;
