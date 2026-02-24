WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName
),

StringProcessing AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.CommentCount,
        rp.VoteCount,
        STRING_AGG(tag.TagName, ', ') AS AllTags,
        CASE 
            WHEN CHAR_LENGTH(rp.Body) > 1000 THEN 'Long Body'
            ELSE 'Short Body'
        END AS BodyLengthCategory,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Votes WHERE PostId = rp.PostId AND VoteTypeId = 2) THEN 'Popular'
            ELSE 'Less Popular'
        END AS PopularityCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(rp.Tags, '<>')) AS TagName
        ) AS tag ON TRUE
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.OwnerDisplayName, rp.CreationDate, rp.CommentCount, rp.VoteCount
)

SELECT 
    sp.PostId,
    sp.Title,
    sp.OwnerDisplayName,
    sp.CreationDate,
    sp.CommentCount,
    sp.VoteCount,
    sp.AllTags,
    sp.BodyLengthCategory,
    sp.PopularityCategory
FROM 
    StringProcessing sp
WHERE 
    sp.VoteCount > 5  
ORDER BY 
    sp.CreationDate DESC;