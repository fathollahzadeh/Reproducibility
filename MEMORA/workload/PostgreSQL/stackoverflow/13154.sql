WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CombinedStatistics AS (
    SELECT 
        us.UserId,
        us.BadgeCount,
        us.TotalUpVotes,
        us.TotalDownVotes,
        us.AverageReputation,
        ps.TotalPosts,
        ps.TotalScore,
        ps.TotalQuestions,
        ps.TotalAnswers
    FROM 
        UserStatistics us
    LEFT JOIN 
        PostStatistics ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    UserId,
    BadgeCount,
    TotalUpVotes,
    TotalDownVotes,
    AverageReputation,
    TotalPosts,
    TotalScore,
    TotalQuestions,
    TotalAnswers
FROM 
    CombinedStatistics
ORDER BY 
    TotalPosts DESC, TotalScore DESC
LIMIT 10;