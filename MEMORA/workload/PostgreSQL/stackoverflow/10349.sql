WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.VoteAmount, 0)) AS TotalVotes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteAmount
         FROM 
            Votes
         GROUP BY 
            PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.TotalViews,
    ua.TotalVotes,
    ua.QuestionCount,
    ua.AnswerCount,
    CAST(ua.TotalViews AS FLOAT) / NULLIF(ua.PostCount, 0) AS AverageViewsPerPost,
    CAST(ua.TotalVotes AS FLOAT) / NULLIF(ua.PostCount, 0) AS AverageVotesPerPost
FROM 
    UserActivity ua
ORDER BY 
    ua.TotalVotes DESC
LIMIT 100;