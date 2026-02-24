
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Score, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 3 
),
TagStatistics AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(Tags, '> <')) AS Tag, 
        COUNT(*) AS TagCount
    FROM 
        TopPosts
    GROUP BY 
        Tag
)
SELECT 
    ts.Tag,
    ts.TagCount,
    tp.OwnerDisplayName,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    TagStatistics ts
JOIN 
    TopPosts tp ON ts.Tag = ANY(STRING_TO_ARRAY(tp.Tags, '> <'))
ORDER BY 
    ts.TagCount DESC, tp.Score DESC;
