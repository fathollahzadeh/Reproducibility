
WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 500
    GROUP BY 
        u.Id, u.DisplayName
),
UserActivityTrend AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalBounties,
        PostRank,
        LAG(TotalPosts) OVER (ORDER BY PostRank) AS PreviousPostCount
    FROM 
        RecursiveUserActivity
),
ActivityGrowth AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalBounties,
        CASE 
            WHEN PreviousPostCount IS NULL THEN NULL
            ELSE TotalPosts - PreviousPostCount 
        END AS PostGrowth
    FROM 
        UserActivityTrend
)
SELECT 
    u.Id,
    u.DisplayName,
    COALESCE(ag.PostGrowth, 0) AS RecentPostChange,
    ag.TotalPosts,
    ag.TotalAnswers,
    ag.TotalQuestions,
    ag.TotalBounties
FROM 
    ActivityGrowth ag
JOIN 
    Users u ON ag.UserId = u.Id
WHERE 
    ag.PostGrowth IS NOT NULL AND ag.PostGrowth > 0
ORDER BY 
    ag.PostGrowth DESC
LIMIT 10;
