
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViewCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostTypeCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(CASE WHEN PostTypeId = 4 THEN 1 END) AS TagWikiCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    us.BadgeCount,
    us.PostCount,
    us.TotalViewCount,
    us.TotalScore,
    ptc.QuestionCount,
    ptc.AnswerCount,
    ptc.TagWikiCount
FROM 
    Users u
JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    PostTypeCounts ptc ON u.Id = ptc.OwnerUserId
ORDER BY 
    us.TotalViewCount DESC,
    us.TotalScore DESC;
