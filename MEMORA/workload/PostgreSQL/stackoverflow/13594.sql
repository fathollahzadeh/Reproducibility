WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        AVG(vote_counts.VoteCount) AS AvgVotesPerPost,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS vote_counts ON p.Id = vote_counts.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    COALESCE(AvgVotesPerPost, 0) AS AvgVotesPerPost,
    QuestionCount,
    AnswerCount,
    WikiCount,
    (PostCount * 100.0 / NULLIF((SELECT COUNT(*) FROM Posts), 0)) AS PostPercentage
FROM 
    UserPostStats
ORDER BY 
    PostCount DESC;