WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > 0
),
MostCommentedPosts AS (
    SELECT 
        PostId, 
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        t.TagName,
        COALESCE(cm.CommentCount, 0) as TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS TagArray(Tag) ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(TagArray.Tag)
    LEFT JOIN 
        MostCommentedPosts cm ON p.Id = cm.PostId
)
SELECT 
    wp.PostId,
    wp.Title,
    wp.TagName,
    wp.TotalComments,
    rp.OwnerName
FROM 
    PostsWithTags wp
JOIN 
    RankedPosts rp ON wp.PostId = rp.PostId
WHERE 
    rp.PostRank = 1
    AND wp.TotalComments > 5
ORDER BY 
    wp.TotalComments DESC, 
    rp.CreationDate DESC
LIMIT 10;