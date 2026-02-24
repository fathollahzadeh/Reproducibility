WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalCommentCount,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVoteCount,
        MAX(u.CreationDate) AS AccountCreated
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    UserId, 
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalCommentCount,
    TotalVoteCount,
    AccountCreated
FROM 
    UserActivity
ORDER BY 
    PostCount DESC
LIMIT 10;