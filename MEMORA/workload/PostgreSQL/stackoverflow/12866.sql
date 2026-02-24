WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.VoteCount AS TotalVotes,
    u.UpVotes,
    u.DownVotes,
    p.PostId,
    p.Title AS PostTitle,
    p.ViewCount AS TotalViews,
    p.AnswerCount AS TotalAnswers,
    p.CommentCount AS TotalComments,
    p.VoteCount AS PostVoteCount
FROM 
    UserVoteStats u
JOIN 
    PostStats p ON u.UserId = p.PostId 
ORDER BY 
    u.VoteCount DESC, p.ViewCount DESC
LIMIT 100;