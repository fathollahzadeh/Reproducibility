WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><') ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'  
),

TopTags AS (
    SELECT 
        unnest(STRING_TO_ARRAY(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10  
),

MostCommonTags AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount
    FROM 
        TopTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 5  
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    mc.Tag AS CommonTag,
    mc.TagCount
FROM 
    RankedPosts rp
JOIN 
    MostCommonTags mc ON mc.Tag = ANY(STRING_TO_ARRAY(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.ViewCount DESC;