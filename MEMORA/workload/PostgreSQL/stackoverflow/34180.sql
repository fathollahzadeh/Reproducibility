WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND 
        p.Score > 0
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        array_agg(t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(p.Tags, '><')) AS tag ON true
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),
PostStats AS (
    SELECT 
        pt.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        PostTags pt
    LEFT JOIN 
        Comments c ON pt.PostId = c.PostId
    LEFT JOIN 
        Votes v ON pt.PostId = v.PostId
    GROUP BY 
        pt.PostId
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Score,
    trp.CreationDate,
    trp.OwnerDisplayName,
    pt.Tags,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostTags pt ON trp.PostId = pt.PostId
LEFT JOIN 
    PostStats ps ON trp.PostId = ps.PostId
ORDER BY 
    trp.Score DESC;