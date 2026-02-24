WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
AggregatedData AS (
    SELECT 
        u.Reputation,
        u.CreationDate,
        MAX(ps.TotalComments) AS MaxComments,
        SUM(ps.QuestionCount) AS TotalQuestions,
        SUM(ps.AnswerCount) AS TotalAnswers,
        SUM(uvs.TotalVotes) AS TotalUserVotes,
        SUM(uvs.UpVotes) AS TotalUserUpVotes,
        SUM(uvs.DownVotes) AS TotalUserDownVotes
    FROM 
        Users u
    LEFT JOIN 
        UserVoteStats uvs ON u.Id = uvs.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.PostId
    GROUP BY 
        u.Reputation, u.CreationDate
)
SELECT 
    Reputation,
    CreationDate,
    MaxComments,
    TotalQuestions,
    TotalAnswers,
    TotalUserVotes,
    TotalUserUpVotes,
    TotalUserDownVotes
FROM 
    AggregatedData
ORDER BY 
    Reputation DESC
LIMIT 100;