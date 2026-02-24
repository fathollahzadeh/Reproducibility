
WITH RECURSIVE PostHierarchy AS (
    SELECT Id, Title, ParentId, CreationDate, Score, 0 AS Level
    FROM Posts
    WHERE ParentId IS NULL 

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, p.CreationDate, p.Score, ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        SUM(CASE WHEN p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days') THEN 1 ELSE 0 END) AS RecentPostsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(com.CommentCount, 0) AS CommentCount,
        COALESCE(vote.UpVotesCount, 0) AS UpVotesCount,
        COALESCE(vote.DownVotesCount, 0) AS DownVotesCount,
        ph.Level,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) com ON p.Id = com.PostId
    LEFT JOIN (
        SELECT 
            p.Id,
            SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
            SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
        FROM Posts p
        LEFT JOIN Votes v ON p.Id = v.PostId
        GROUP BY p.Id
    ) vote ON p.Id = vote.Id
    LEFT JOIN PostHierarchy ph ON p.Id = ph.Id
)
SELECT 
    ua.DisplayName,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.UpVotesCount) AS TotalUpVotes,
    SUM(ps.DownVotesCount) AS TotalDownVotes,
    COUNT(DISTINCT ps.Id) AS PostsParticipated,
    COUNT(DISTINCT ph.ParentId) FILTER (WHERE ph.Level = 1) AS DirectAnswers
FROM UserActivity ua
LEFT JOIN PostStats ps ON ua.UserId = ps.OwnerUserId
LEFT JOIN PostHierarchy ph ON ps.Id = ph.Id
GROUP BY ua.UserId, ua.DisplayName
HAVING COUNT(DISTINCT ps.Id) > 0
ORDER BY TotalUpVotes DESC;
