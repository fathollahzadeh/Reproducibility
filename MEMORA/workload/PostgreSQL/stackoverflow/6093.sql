
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalScores
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostAnalysis AS (
    SELECT 
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        MAX(p.Score) AS MaxScore,
        AVG(COALESCE(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)), 0)) AS AvgResolutionTime
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId, p.PostTypeId
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.BadgeCount,
    ur.PostCount,
    ur.TotalAnswers,
    ur.TotalScores,
    pa.PostTypeId,
    pa.CommentCount,
    pa.MaxScore,
    pa.AvgResolutionTime
FROM 
    UserReputation ur
INNER JOIN 
    PostAnalysis pa ON ur.UserId = pa.OwnerUserId
WHERE 
    ur.Reputation > 1000
ORDER BY 
    ur.Reputation DESC, 
    pa.MaxScore DESC;
