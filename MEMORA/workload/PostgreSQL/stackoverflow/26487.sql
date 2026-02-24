WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TagCount,
        rp.OwnerDisplayName
    FROM RankedPosts rp
    WHERE rp.TagCount > 5  
      AND rp.PostRank <= 5  
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.OwnerDisplayName,
    (
        SELECT COUNT(*)
        FROM Comments c
        WHERE c.PostId = fp.PostId
    ) AS CommentCount,
    (
        SELECT COUNT(*)
        FROM Votes v
        WHERE v.PostId = fp.PostId AND v.VoteTypeId = 2 
    ) AS UpVoteCount
FROM FilteredPosts fp
ORDER BY fp.Score DESC, fp.ViewCount DESC;