WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        0 AS Depth
    FROM Users
    WHERE Reputation >= 1000

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        ur.Depth + 1
    FROM Users u
    INNER JOIN UserReputation ur ON u.Id = ur.Id
    WHERE ur.Depth < 5
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(p.CreationDate) AS LastActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.OwnerUserId
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.CommentCount, 0) AS TotalComments,
        COALESCE(ps.VoteCount, 0) AS TotalVotes,
        COALESCE(ps.UpvoteCount, 0) AS TotalUpvotes,
        COALESCE(ps.DownvoteCount, 0) AS TotalDownvotes,
        COALESCE(ps.EditCount, 0) AS TotalEdits
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
),
TopUsers AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.TotalComments,
        um.TotalVotes,
        um.TotalUpvotes,
        um.TotalDownvotes,
        um.TotalEdits,
        ROW_NUMBER() OVER (ORDER BY um.TotalComments DESC) AS Rank
    FROM UserMetrics um
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.TotalComments,
    tu.TotalVotes,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    tu.TotalEdits,
    ur.Reputation
FROM TopUsers tu
JOIN UserReputation ur ON tu.UserId = ur.Id
WHERE tu.Rank <= 10
ORDER BY ur.Reputation DESC;
