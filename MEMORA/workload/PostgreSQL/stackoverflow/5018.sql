WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
QualifiedUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.BadgeCount,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.TotalViews,
        ps.AverageScore 
    FROM 
        UserReputation ur
    JOIN 
        PostStats ps ON ur.UserId = ps.OwnerUserId
    WHERE 
        ur.Reputation > 100 AND 
        ps.TotalPosts > 10
),
FinalReport AS (
    SELECT 
        q.DisplayName,
        q.Reputation,
        q.BadgeCount,
        q.TotalPosts,
        q.Questions,
        q.Answers,
        q.TotalViews,
        q.AverageScore,
        RANK() OVER (ORDER BY q.Reputation DESC) AS ReputationRank
    FROM 
        QualifiedUsers q
)
SELECT 
    DisplayName,
    Reputation,
    BadgeCount,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    AverageScore,
    ReputationRank
FROM 
    FinalReport
WHERE 
    ReputationRank <= 10
ORDER BY 
    Reputation DESC;
