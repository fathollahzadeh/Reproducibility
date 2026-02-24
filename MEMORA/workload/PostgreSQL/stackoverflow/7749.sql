
WITH UserVoteStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        TotalVotes,
        RANK() OVER (ORDER BY UpVotes DESC) AS Rank
    FROM UserVoteStatistics
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        Score,
        ViewCount,
        CommentCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Score DESC) AS Rank
    FROM PostStatistics
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS ActivityRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
)
SELECT 
    tu.Rank AS UserRank,
    tu.DisplayName AS UserName,
    tp.Rank AS PostRank,
    tp.Title AS PostTitle,
    tp.Score AS PostScore,
    tp.ViewCount AS PostViews,
    ra.CreationDate AS RecentPostDate,
    ra.Author AS PostAuthor
FROM TopUsers tu
JOIN TopPosts tp ON tu.UpVotes > 0
JOIN RecentActivity ra ON tp.PostId = ra.PostId
WHERE tu.Rank <= 10 AND tp.Rank <= 10 AND ra.ActivityRank = 1
ORDER BY tu.Rank, tp.Rank;
