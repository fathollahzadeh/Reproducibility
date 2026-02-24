WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS Contributors
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.Id, pt.Name, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags
),
TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(*) AS TotalContributions
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(*) > 5
),
PostTags AS (
    SELECT
        p.Id AS PostId,
        unnest(string_to_array(p.Tags, ',')) AS Tag
    FROM Posts p
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.Contributors,
    tt.TotalContributions,
    COUNT(pt.Tag) AS TagCount
FROM RankedPosts rp
LEFT JOIN TopContributors tt ON rp.Contributors LIKE '%' || tt.DisplayName || '%'
LEFT JOIN PostTags pt ON rp.PostId = pt.PostId
WHERE rp.Rank <= 5
GROUP BY rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.Score, rp.Tags, rp.Contributors, tt.TotalContributions
ORDER BY rp.Score DESC;