
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        AVG(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
BadgeDetails AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS TotalPostHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)  
    GROUP BY 
        ph.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.AvgViewCount,
    COALESCE(bd.TotalBadges, 0) AS TotalBadges,
    COALESCE(bd.BadgeNames, 'None') AS BadgeNames,
    COALESCE(phc.TotalPostHistory, 0) AS TotalPostHistory
FROM 
    UserStats us
LEFT JOIN 
    BadgeDetails bd ON us.UserId = bd.UserId
LEFT JOIN 
    PostHistoryCounts phc ON us.UserId = phc.UserId
WHERE 
    us.Reputation > 1000  
ORDER BY 
    us.TotalPosts DESC,
    us.Reputation DESC
FETCH FIRST 50 ROWS ONLY;
