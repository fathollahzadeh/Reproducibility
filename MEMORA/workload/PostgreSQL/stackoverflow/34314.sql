WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, LastAccessDate, 0 AS Level
    FROM Users
    WHERE Reputation > 1000
    UNION ALL
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate, uh.Level + 1
    FROM Users u
    INNER JOIN UserHierarchy uh ON u.Id = uh.Id
    WHERE u.Reputation < uh.Reputation
),
PostSummary AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1  
),
VoteDetails AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
CommentDetails AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
)
SELECT
    u.DisplayName,
    SUM(ps.ViewCount) AS TotalViews,
    COUNT(DISTINCT ps.PostId) AS TotalPosts,
    COALESCE(SUM(v.UpVotes), 0) - COALESCE(SUM(v.DownVotes), 0) AS NetVotes,
    COALESCE(SUM(cd.CommentCount), 0) AS TotalComments,
    u.Reputation,
    CASE
        WHEN u.Reputation > 10000 THEN 'Elite'
        WHEN u.Reputation > 5000 THEN 'Expert'
        ELSE 'Novice'
    END AS UserLevel
FROM UserHierarchy u
LEFT JOIN PostSummary ps ON ps.OwnerUserId = u.Id
LEFT JOIN VoteDetails v ON v.PostId = ps.PostId
LEFT JOIN CommentDetails cd ON cd.PostId = ps.PostId
WHERE u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
GROUP BY u.Id, u.DisplayName, u.Reputation
HAVING COUNT(DISTINCT ps.PostId) > 5 
ORDER BY TotalViews DESC;