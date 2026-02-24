
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.OwnerUserId, p.CreationDate
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 5
),
LatestUserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    ru.DisplayName AS UserName,
    ru.Reputation,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    lut.LastActivityDate,
    pt.TagName
FROM RankedUsers ru
JOIN RecentPosts rp ON ru.UserId = rp.OwnerUserId
LEFT JOIN LatestUserActivity lut ON ru.UserId = lut.UserId
JOIN PopularTags pt ON pt.PostCount >= 1
WHERE ru.ReputationRank <= 10
  AND rp.CommentCount IS NOT NULL
  AND lut.LastActivityDate IS NOT NULL
ORDER BY ru.Reputation DESC, rp.UpVoteCount DESC;
