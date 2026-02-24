
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Upvotes,
        Downvotes,
        ROW_NUMBER() OVER (ORDER BY Upvotes DESC) AS RN
    FROM UserVoteStats
    WHERE PostCount > 10
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(bt.Class), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges bt ON p.OwnerUserId = bt.UserId
    GROUP BY p.Id, p.Title, p.CreationDate
),
BalancedPerformance AS (
    SELECT 
        tu.DisplayName,
        tu.Upvotes,
        tu.Downvotes,
        uvs.PostCount,
        pa.CommentCount,
        pa.TotalBadges,
        (tu.Upvotes - tu.Downvotes) AS NetVotes,
        DENSE_RANK() OVER (ORDER BY (tu.Upvotes - tu.Downvotes) DESC) AS NetVoteRank
    FROM TopUsers tu
    JOIN UserVoteStats uvs ON tu.UserId = uvs.UserId
    JOIN PostActivity pa ON uvs.PostCount > 5
    WHERE tu.RN <= 10
)
SELECT 
    bp.DisplayName,
    bp.Upvotes,
    bp.Downvotes,
    bp.NetVotes,
    bp.CommentCount,
    bp.TotalBadges,
    bp.NetVoteRank
FROM BalancedPerformance bp
WHERE bp.NetVoteRank <= 5
ORDER BY bp.NetVotes DESC, bp.CommentCount DESC;
