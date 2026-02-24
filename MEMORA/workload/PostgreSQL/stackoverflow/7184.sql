WITH PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.TotalViews,
    ps.AverageScore,
    CASE 
        WHEN ur.Reputation < 100 THEN 'Newbie'
        WHEN ur.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserTier
FROM 
    UserReputation ur
JOIN 
    PostStats ps ON ur.UserId = ps.OwnerUserId
ORDER BY 
    ps.TotalViews DESC, 
    ps.AverageScore DESC;
