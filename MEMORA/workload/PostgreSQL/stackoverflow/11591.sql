
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(vs.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(vs.DownVotes, 0)) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
             PostId, 
             SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
             SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
             Votes
         GROUP BY 
             PostId) vs ON p.Id = vs.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount
),
BenchmarkResults AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalScore,
        ups.TotalUpVotes,
        ups.TotalDownVotes,
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.ViewCount,
        pa.AnswerCount,
        pa.CommentCount,
        pa.LastEditDate,
        pa.TotalComments
    FROM 
        UserPostStats ups
    LEFT JOIN 
        PostActivity pa ON ups.UserId = pa.PostId  -- Fixed Join Condition
)
SELECT 
    *
FROM 
    BenchmarkResults
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
