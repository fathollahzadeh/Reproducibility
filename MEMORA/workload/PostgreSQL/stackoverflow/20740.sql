WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.AcceptedAnswerId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.PostId = p.Id
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
DetailedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        PHT.Name AS PostHistoryTypeName
    FROM PostHistory ph
    JOIN PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
DistinctTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM Posts p
    LEFT JOIN LATERAL 
        (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName) AS t ON TRUE
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    dt.TagsList,
    dph.HistoryDate,
    dph.UserDisplayName,
    dph.Comment,
    dph.Text,
    dph.PostHistoryTypeName,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 
            (SELECT Title FROM Posts WHERE Id = rp.AcceptedAnswerId)
        ELSE 'No Accepted Answer'
    END AS AcceptedAnswerTitle
FROM RankedPosts rp
LEFT JOIN DistinctTags dt ON rp.PostId = dt.PostId
LEFT JOIN DetailedPostHistory dph ON rp.PostId = dph.PostId 
WHERE rp.PostRank = 1 
AND (rp.ViewCount > 100 OR dt.TagsList IS NOT NULL)
ORDER BY rp.CreationDate DESC
LIMIT 50;