WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
),
PostsStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.CreationDate,
        us.LastAccessDate,
        us.BadgeCount,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.AvgScore,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS Rank
    FROM 
        UserStats us
    LEFT JOIN 
        PostsStats ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    cs.UserId,
    cs.DisplayName,
    cs.Reputation,
    cs.CreationDate,
    cs.LastAccessDate,
    cs.BadgeCount,
    COALESCE(cs.TotalPosts, 0) AS TotalPosts,
    COALESCE(cs.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(cs.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(cs.AvgScore, 0) AS AvgScore,
    cs.Rank,
    CASE 
        WHEN cs.BadgeCount = 0 THEN 'No Badges'
        WHEN cs.BadgeCount <= 3 THEN 'Novice'
        WHEN cs.BadgeCount <= 10 THEN 'Intermediate'
        ELSE 'Expert'
    END AS BadgeLevel
FROM 
    CombinedStats cs
WHERE 
    cs.Reputation > 50 OR cs.TotalPosts > 10
ORDER BY 
    cs.Rank
LIMIT 100
OFFSET 0;
