
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
        AND p.Score > 0
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    rp.Title,
    rp.OwnerName,
    rp.Score,
    rp.ViewCount,
    pt.PostCount,
    pt.TagName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
JOIN 
    PopularTags pt ON p.Id IN (SELECT PostId FROM Posts WHERE Tags LIKE '%' || pt.TagName || '%')
WHERE 
    rp.ScoreRank <= 5 
    AND p.PostTypeId = 1
GROUP BY 
    rp.Title, rp.OwnerName, rp.Score, rp.ViewCount, pt.PostCount, pt.TagName, rp.PostId
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
