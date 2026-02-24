WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalCommentsCount,
        SUM(COALESCE(b.Id, 0)) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ua.DisplayName,
    ua.PostsCount,
    ua.QuestionsCount,
    ua.AnswersCount,
    ua.TotalScore,
    ua.TotalCommentsCount,
    ua.BadgesCount
FROM 
    UserActivity ua
ORDER BY 
    ua.TotalScore DESC
LIMIT 10;