WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
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
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 3  
)

SELECT 
    fp.OwnerDisplayName,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.VoteCount,
    STRING_AGG(t.TagName, ', ') AS RelatedTags
FROM 
    FilteredPosts fp
LEFT JOIN 
    Tags t ON t.TagName = ANY(STRING_TO_ARRAY(fp.Tags, ','))
GROUP BY 
    fp.OwnerDisplayName, fp.Title, fp.CreationDate, fp.CommentCount, fp.VoteCount
ORDER BY 
    fp.CreationDate DESC;