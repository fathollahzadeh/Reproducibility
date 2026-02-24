WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
DetailedUserStatistics AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalScore,
        us.TotalBadges,
        COALESCE(ph.EditCount, 0) AS EditCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount
    FROM 
        UserStatistics us
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS EditCount
        FROM 
            PostHistory
        GROUP BY 
            UserId
    ) ph ON us.UserId = ph.UserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            UserId
    ) c ON us.UserId = c.UserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            UserId
    ) v ON us.UserId = v.UserId
)
SELECT 
    dus.UserId,
    dus.DisplayName,
    dus.TotalPosts,
    dus.TotalQuestions,
    dus.TotalAnswers,
    dus.TotalScore,
    dus.EditCount,
    dus.CommentCount,
    dus.VoteCount,
    RANK() OVER (ORDER BY dus.TotalScore DESC) AS ScoreRank
FROM 
    DetailedUserStatistics dus
ORDER BY 
    dus.TotalScore DESC, dus.DisplayName ASC
LIMIT 10;
