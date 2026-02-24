WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(DISTINCT p.Id) > 50
),
TopUsers AS (
    SELECT 
        s.UserId,
        s.DisplayName,
        s.Reputation,
        ROW_NUMBER() OVER (ORDER BY s.Reputation DESC) AS Rank
    FROM UserStats s
    WHERE s.PostCount > 10
)
SELECT 
    u.DisplayName AS TopUser,
    u.Reputation AS Reputation,
    t.TagName AS PopularTag,
    t.PostCount AS TagPostCount
FROM TopUsers u
JOIN PopularTags t ON u.UserId IN (
    SELECT DISTINCT p.OwnerUserId
    FROM Posts p
    WHERE p.Tags LIKE '%' || t.TagName || '%'
)
WHERE u.Rank <= 10
ORDER BY u.Reputation DESC, t.PostCount DESC;
