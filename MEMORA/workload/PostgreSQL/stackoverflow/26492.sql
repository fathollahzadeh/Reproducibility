
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, U.DisplayName, p.Title, p.Body, p.CreationDate, p.ViewCount
),
PopularTags AS (
    SELECT 
        TRIM(BOTH '<>' FROM unnest(string_to_array(p.Tags, '><'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
TagDetails AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        MIN(p.CreationDate) AS FirstUsed,
        MAX(p.CreationDate) AS LastUsed
    FROM 
        PopularTags pt
    JOIN 
        Tags t ON pt.TagName = t.TagName
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    rp.OwnerDisplayName,
    rp.Title,
    rp.CommentCount,
    rp.AnswerCount,
    tt.TagName,
    tt.PostCount,
    tt.FirstUsed,
    tt.LastUsed,
    rp.CreationDate,
    rp.ViewCount
FROM 
    RankedPosts rp
JOIN 
    TagDetails tt ON tt.TagName = ANY (string_to_array(rp.Body, ' '))  
WHERE 
    rp.OwnerPostRank <= 5  
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC;
