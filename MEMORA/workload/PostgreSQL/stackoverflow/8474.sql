
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT UserId, DisplayName, Reputation, PostCount, AnswerCount, QuestionCount
    FROM RankedUsers
    WHERE ReputationRank <= 10
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS PostDate,
    rp.OwnerName,
    rp.CommentCount,
    rp.AvgUpvotes,
    rp.DownvoteCount
FROM TopUsers tu
JOIN RecentPosts rp ON tu.DisplayName = rp.OwnerName
ORDER BY tu.Reputation DESC, rp.CreationDate DESC;
