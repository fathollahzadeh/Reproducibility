
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Body,
    trp.CreationDate,
    trp.Score,
    trp.OwnerDisplayName,
    trp.CommentCount,
    pt.Tags,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = trp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = trp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostTags pt ON trp.PostId = pt.PostId
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC
LIMIT 10;
