
WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.CreationDate,
           p.Body,
           p.Tags,
           p.ViewCount,
           p.Score,
           u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),
TaggedPosts AS (
    SELECT rp.Id,
           rp.Title,
           rp.CreationDate,
           rp.Body,
           rp.ViewCount,
           rp.Score,
           rp.OwnerDisplayName,
           STRING_AGG(t.TagName, ', ') AS TagsAggregated
    FROM RankedPosts rp
    LEFT JOIN Tags t ON t.TagName IN (SELECT unnest(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><')))
    GROUP BY rp.Id, rp.Title, rp.CreationDate, rp.Body, rp.ViewCount, rp.Score, rp.OwnerDisplayName
),
HighScoringPosts AS (
    SELECT * 
    FROM TaggedPosts 
    WHERE Score > 100
),
PostSummary AS (
    SELECT hsp.Id,
           hsp.Title,
           hsp.OwnerDisplayName,
           hsp.CreationDate,
           hsp.Score,
           hsp.TagsAggregated,
           (SELECT COUNT(*) FROM Comments c WHERE c.PostId = hsp.Id) AS CommentCount,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = hsp.Id AND v.VoteTypeId = 2) AS UpvoteCount
    FROM HighScoringPosts hsp 
)

SELECT ps.Id,
       ps.Title,
       ps.OwnerDisplayName,
       ps.CreationDate,
       ps.Score,
       ps.TagsAggregated,
       ps.CommentCount,
       ps.UpvoteCount,
       CASE 
           WHEN ps.Score < 200 THEN 'Medium Score' 
           ELSE 'High Score' 
       END AS ScoreCategory
FROM PostSummary ps
WHERE ps.CommentCount > 5
ORDER BY ps.Score DESC, ps.CreationDate DESC;
