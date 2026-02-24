WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
PopularPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > 10 
    ORDER BY 
        rp.ViewCount DESC
    LIMIT 10
)
SELECT 
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.OwnerDisplayName,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pp.Id AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pp.Id AND v.VoteTypeId = 3) AS DownVotes,
    (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE pp.Id IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE CONCAT('%<', t.TagName, '>%'))) AS RelatedTags
FROM 
    PopularPosts pp
JOIN 
    PostHistory ph ON pp.Id = ph.PostId
WHERE 
    ph.PostHistoryTypeId = 10 
GROUP BY 
    pp.Id, pp.Title, pp.CreationDate, pp.ViewCount, pp.OwnerDisplayName
ORDER BY 
    pp.ViewCount DESC;