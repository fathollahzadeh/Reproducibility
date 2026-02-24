
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate))) AS AvgPostAgeInSeconds
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
BadgeCounts AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS TotalBadges 
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryStats AS (
    SELECT 
        ph.UserId, 
        COUNT(ph.Id) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS TotalEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.AvgPostAgeInSeconds,
    COALESCE(bc.TotalBadges, 0) AS TotalBadges,
    COALESCE(phs.EditCount, 0) AS TotalEdits,
    COALESCE(phs.TotalEdits, 0) AS TotalContentEdits
FROM 
    UserStats us
LEFT JOIN 
    BadgeCounts bc ON us.UserId = bc.UserId
LEFT JOIN 
    PostHistoryStats phs ON us.UserId = phs.UserId
WHERE 
    us.Reputation > 100
ORDER BY 
    us.Reputation DESC, 
    us.TotalPosts DESC;
