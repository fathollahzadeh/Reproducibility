
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Views) AS AvgViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AvgViews,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStatistics
),
ActiveUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        u.TotalPosts,
        u.AvgViews,
        COUNT(c.Id) AS CommentsMade
    FROM TopUsers u
    LEFT JOIN Comments c ON u.UserId = c.UserId
    GROUP BY u.UserId, u.DisplayName, u.Reputation, u.TotalPosts, u.AvgViews
),
PostsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        v.VoteTypeId,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.Score, v.VoteTypeId
),
PostAnalysis AS (
    SELECT 
        p.PostId,
        p.Title,
        SUM(CASE WHEN p.VoteTypeId = 2 THEN p.VoteCount ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN p.VoteTypeId = 3 THEN p.VoteCount ELSE 0 END) AS TotalDownVotes
    FROM PostsWithVotes p
    GROUP BY p.PostId, p.Title
)
SELECT 
    au.DisplayName,
    au.Reputation,
    au.TotalPosts,
    au.AvgViews,
    pa.Title,
    pa.TotalUpVotes,
    pa.TotalDownVotes
FROM ActiveUsers au
JOIN PostAnalysis pa ON au.UserId = pa.PostId
WHERE au.CommentsMade > 5
ORDER BY au.Reputation DESC, pa.TotalUpVotes DESC;
