WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankScore,
        ARRAY_AGG(t.TagName) AS TagsList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' 
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.PostType,
        rp.Score,
        rp.ViewCount,
        rp.RankScore,
        rp.TagsList
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerName,
    fp.PostType,
    fp.Score,
    fp.ViewCount,
    fp.TagsList,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    FilteredPosts fp
LEFT JOIN 
    Comments c ON fp.PostId = c.PostId
LEFT JOIN 
    Votes v ON fp.PostId = v.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerName, fp.PostType, fp.Score, fp.ViewCount, fp.TagsList
ORDER BY 
    fp.Score DESC, COUNT(c.Id) DESC;