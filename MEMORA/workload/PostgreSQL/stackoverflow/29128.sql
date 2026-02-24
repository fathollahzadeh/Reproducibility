
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.Score DESC) as Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND 
          p.Score > 0 AND 
          p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TagSummary AS (
    SELECT 
        LOWER(TRIM(regexp_split_to_table(p.Tags, '>'))) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts p
    WHERE p.PostTypeId = 1
    GROUP BY LOWER(TRIM(regexp_split_to_table(p.Tags, '>')))
),
PopularTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        RANK() OVER (ORDER BY ts.PostCount DESC) AS TagRank
    FROM TagSummary ts
    WHERE ts.PostCount > 10
),
PostInteraction AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    pi.CommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount,
    pt.TagName AS RelatedTag
FROM RankedPosts rp
JOIN PostInteraction pi ON rp.PostId = pi.PostId
LEFT JOIN PopularTags pt ON pt.TagName = ANY(STRING_TO_ARRAY(rp.Tags, '>'))
WHERE rp.Rank <= 5
ORDER BY rp.Score DESC, pi.UpVoteCount DESC;
