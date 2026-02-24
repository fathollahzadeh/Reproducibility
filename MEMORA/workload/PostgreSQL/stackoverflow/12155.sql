
WITH UserReputation AS (
    SELECT Id AS UserId, Reputation
    FROM Users
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    JOIN Users u ON p.OwnerUserId = u.Id
),
TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    CROSS JOIN UNNEST(string_to_array(p.Tags, '><')) AS tag
    JOIN Tags t ON t.TagName = tag
    GROUP BY p.Id
)
SELECT
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.PostType,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    tp.Tags
FROM PostDetails pd
LEFT JOIN TaggedPosts tp ON pd.PostId = tp.PostId
ORDER BY pd.ViewCount DESC
LIMIT 100;
