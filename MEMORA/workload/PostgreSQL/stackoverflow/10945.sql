
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount, 
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 END) AS TagWikiCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViewCount
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
)

SELECT 
    pts.PostTypeId,
    pts.QuestionCount,
    pts.AnswerCount,
    pts.TagWikiCount,
    pts.TotalScore,
    pts.TotalViewCount,
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.VoteCount
FROM 
    PostStats pts
JOIN 
    UserStats us ON us.VoteCount > 0
ORDER BY 
    pts.TotalScore DESC, 
    us.Reputation DESC;
