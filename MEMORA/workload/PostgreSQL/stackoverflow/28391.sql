
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.UpvoteCount - rp.DownvoteCount > 10 THEN 'Highly Voted'
            WHEN rp.UpvoteCount - rp.DownvoteCount BETWEEN 1 AND 10 THEN 'Moderately Voted'
            ELSE 'Low Interaction' 
        END AS VoteCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
),
TagsStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '>'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        TopPosts
    GROUP BY 
        TRIM(UNNEST(string_to_array(Tags, '>')))
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    tp.VoteCategory,
    ts.TagName,
    ts.TagCount
FROM 
    TopPosts tp
LEFT JOIN 
    TagsStats ts ON tp.Tags LIKE '%' || ts.TagName || '%'
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
