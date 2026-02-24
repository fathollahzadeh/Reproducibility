
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id 
    LEFT JOIN Badges b ON b.UserId = u.Id
    WHERE u.Reputation >= 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
), 
TopUsers AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.Reputation,
        um.TotalUpVotes,
        um.TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY (um.TotalUpVotes - um.TotalDownVotes) DESC, um.Reputation DESC) AS UserRank
    FROM UserMetrics um
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    CASE 
        WHEN tu.UserRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory,
    (SELECT 
        STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p
     JOIN UNNEST(STRING_TO_ARRAY(p.Tags, ', ')) AS tagArray ON tagArray IS NOT NULL
     JOIN Tags t ON t.TagName = TRIM(tagArray)
     WHERE p.OwnerUserId = tu.UserId) AS UserTags,
    (SELECT 
        COALESCE(STRING_AGG(DISTINCT c.Text, '; '), 'No Comments') 
        FROM Comments c 
        WHERE c.UserId = tu.UserId) AS UserComments
FROM TopUsers tu
WHERE tu.UserId IN (
    SELECT DISTINCT u.Id 
    FROM Users u 
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id 
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
)
ORDER BY tu.UserRank
LIMIT 50;
