WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        STRING_AGG(t.TagName, ', ') AS TagsList,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        rp.TagsList
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 
),
PopularTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    tp.TagsList,
    pt.TagName AS PopularTag
FROM 
    TopPosts tp
CROSS JOIN 
    PopularTags pt
ORDER BY 
    tp.CreationDate DESC, pt.TagCount DESC;