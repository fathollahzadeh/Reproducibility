WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.CreationDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate
    HAVING COUNT(c.Id) > 5
),
TopUsers AS (
    SELECT 
        ur.UserId,
        SUM(CASE WHEN pp.CommentCount > 10 THEN 1 ELSE 0 END) AS ActivePostCount,
        AVG(ur.Reputation) AS AvgReputation
    FROM UserReputation ur
    LEFT JOIN PopularPosts pp ON ur.UserId = pp.PostId
    GROUP BY ur.UserId
),
RankedUsers AS (
    SELECT 
        UserId,
        ActivePostCount,
        AvgReputation,
        RANK() OVER (ORDER BY AvgReputation DESC, ActivePostCount DESC) AS UserRank
    FROM TopUsers
)
SELECT 
    ru.UserId,
    u.DisplayName,
    ru.ActivePostCount,
    ru.AvgReputation,
    CASE 
        WHEN ru.ActivePostCount >= 5 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM RankedUsers ru
JOIN Users u ON ru.UserId = u.Id
WHERE ru.UserRank <= 10
ORDER BY ru.AvgReputation DESC, ru.ActivePostCount DESC;
