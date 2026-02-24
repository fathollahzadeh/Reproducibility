WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 

PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.TotalCommentScore,
    COALESCE(ps.Title, 'No Posts') AS MostVotedPostTitle,
    COALESCE(ps.Score, 0) AS MostVotedPostScore,
    ps.ScoreRank,
    ps.ViewRank,
    CASE 
        WHEN ua.TotalPosts > 0 THEN ROUND(100.0 * ua.QuestionCount / ua.TotalPosts, 2)
        ELSE 0.0
    END AS QuestionPercentage
FROM 
    UserActivity ua
LEFT JOIN 
    PostScores ps ON ua.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = (SELECT PostId FROM Votes WHERE VoteTypeId = 2 ORDER BY CreationDate DESC LIMIT 1))
WHERE 
    ua.TotalPosts > 0
ORDER BY 
    ua.TotalCommentScore DESC, 
    ua.DisplayName ASC;