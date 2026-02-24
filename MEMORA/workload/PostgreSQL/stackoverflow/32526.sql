
WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(p.Id) AS PostsCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  
    WHERE u.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY u.Location ORDER BY p.CreationDate DESC) AS LocationRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
      AND p.PostTypeId = 1  
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM Posts p
    JOIN UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags)-2), '>')) AS tag ON tag IS NOT NULL
    JOIN Tags t ON t.TagName = tag
    GROUP BY p.Id
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    p.PostId,
    p.Title AS Recent_Post_Title,
    p.CreationDate AS Recent_Post_CreationDate,
    COALESCE(pt.TagsList, 'No Tags') AS PostTags,
    p.ViewCount,
    p.Score,
    p.OwnerDisplayName,
    ua.TotalBountyAmount
FROM UserActivity ua
FULL OUTER JOIN RecentPosts p ON ua.UserId = (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = p.PostId)
LEFT JOIN PostTags pt ON p.PostId = pt.PostId
WHERE ua.Reputation > 1000 
  AND p.LocationRank <= 3  
ORDER BY ua.Reputation DESC, p.CreationDate DESC;
