
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        PostType
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
TopTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName
    FROM 
        Posts
    WHERE 
        Id IN (SELECT PostId FROM TopPosts)
),
TagUsage AS (
    SELECT 
        TagName,
        COUNT(*) AS UsageCount
    FROM 
        TopTags
    GROUP BY 
        TagName
    ORDER BY 
        UsageCount DESC
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.CommentCount,
    tu.TagName,
    tu.UsageCount
FROM 
    TopPosts tp
JOIN 
    TagUsage tu ON EXISTS (
        SELECT 1 
        FROM Posts 
        WHERE Tags LIKE '%' || tu.TagName || '%'
          AND Id = tp.PostId
    )
ORDER BY 
    tp.ViewCount DESC, tu.UsageCount DESC;
