
WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(ph.Comment, 'No comments') AS LastEditComment,
        ph.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1  
),
FilteredPosts AS (
    SELECT 
        PostID,
        Title,
        Tags,
        CreationDate,
        ViewCount,
        AnswerCount,
        CommentCount,
        Score,
        OwnerDisplayName,
        LastEditComment,
        LastEditDate
    FROM 
        PostAnalytics
    WHERE 
        EditRank = 1  
        AND Score > 10  
        AND ViewCount > 100  
),
TagCount AS (
    SELECT 
        TRIM(tag) AS Tag,
        COUNT(*) AS PostCount
    FROM (
        SELECT 
            unnest(string_to_array(Tags, ',')) AS tag
        FROM 
            FilteredPosts
    ) AS TagsTable
    GROUP BY 
        TRIM(tag
    )
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCount
)
SELECT 
    fp.Title,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.Score,
    fp.OwnerDisplayName,
    tt.Tag,
    tt.PostCount
FROM 
    FilteredPosts fp
JOIN 
    TopTags tt ON tt.Tag IN (SELECT TRIM(tag) FROM unnest(string_to_array(fp.Tags, ',')) AS tag)
WHERE 
    tt.Rank <= 5  
ORDER BY 
    fp.ViewCount DESC, 
    fp.CreationDate DESC;
