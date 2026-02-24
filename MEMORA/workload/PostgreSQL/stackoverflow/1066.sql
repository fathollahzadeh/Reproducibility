
WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        (UpVotes - DownVotes) AS NetScore
    FROM UserScore
    WHERE PostCount > 0
    ORDER BY NetScore DESC
    LIMIT 10
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.LastActivityDate,
        ROW_NUMBER() OVER (ORDER BY p.LastActivityDate DESC) AS ActivityRank
    FROM Posts p
    WHERE p.ViewCount IS NOT NULL
),
RecentPostActivity AS (
    SELECT 
        PostId, 
        Title,
        ViewCount,
        LastActivityDate
    FROM PostActivity
    WHERE ActivityRank <= 5
)
SELECT 
    tu.DisplayName AS TopUser,
    rpa.Title,
    rpa.ViewCount,
    rpa.LastActivityDate
FROM TopUsers tu
JOIN RecentPostActivity rpa ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rpa.PostId)
LEFT JOIN Badges b ON tu.UserId = b.UserId AND b.Class = 1
WHERE b.Id IS NULL OR b.Date < (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
ORDER BY rpa.ViewCount DESC;
