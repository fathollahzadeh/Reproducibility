WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation, u.Views
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.EditCount, 0) AS EditCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS EditCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId IN (4, 5, 6) 
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
),
VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpModCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownModCount
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    us.UserId,
    us.Reputation,
    us.Views,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.UpVoteCount,
    us.DownVoteCount,
    SUM(pa.Score) AS TotalPostScore,
    SUM(pa.ViewCount) AS TotalPostViews,
    SUM(pa.CommentCount) AS TotalComments,
    SUM(pa.EditCount) AS TotalEdits,
    SUM(vs.UpModCount) AS TotalUpVotes,
    SUM(vs.DownModCount) AS TotalDownVotes
FROM 
    UserStatistics us
JOIN 
    Posts p ON us.UserId = p.OwnerUserId
JOIN 
    PostActivity pa ON p.Id = pa.PostId
JOIN 
    VoteStatistics vs ON p.Id = vs.PostId
GROUP BY 
    us.UserId, us.Reputation, us.Views, us.PostCount, us.QuestionCount, us.AnswerCount, us.UpVoteCount, us.DownVoteCount
ORDER BY 
    TotalPostScore DESC, TotalPostViews DESC;