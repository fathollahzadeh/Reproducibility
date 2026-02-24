WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserCommentCounts AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.UserId
),
UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    GROUP BY 
        v.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(p.PostCount, 0) AS TotalPosts,
    COALESCE(p.QuestionCount, 0) AS TotalQuestions,
    COALESCE(p.AnswerCount, 0) AS TotalAnswers,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    COALESCE(v.VoteCount, 0) AS TotalVotes
FROM 
    Users u
LEFT JOIN 
    UserPostCounts p ON u.Id = p.UserId
LEFT JOIN 
    UserCommentCounts c ON u.Id = c.UserId
LEFT JOIN 
    UserVoteCounts v ON u.Id = v.UserId
ORDER BY 
    UserId;