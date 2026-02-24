WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS Deletions,
        array_agg(DISTINCT t.TagName) AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UserRank,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.Deletions,
        rp.TagList
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank = 1 
        AND rp.Score > 10 
        AND rp.CommentCount > 5
)

SELECT 
    f.Id,
    f.Title,
    f.CreationDate,
    f.ViewCount,
    f.Score,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    f.Deletions,
    COALESCE(NULLIF(f.TagList[1], ''), 'No Tags') AS FirstTag
FROM 
    FilteredPosts f
LEFT JOIN 
    Users u ON f.Id = u.Id
WHERE 
    u.Reputation > 1000
ORDER BY 
    f.Score DESC, f.ViewCount DESC;