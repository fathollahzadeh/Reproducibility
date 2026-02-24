
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(co.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY u.Reputation ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, u.Reputation
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TagUsage
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10 
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.CommentCount,
    STRING_AGG(pt.TagName, ', ') AS PopularTags,
    CASE
        WHEN rp.PostRank <= 10 THEN 'Top 10 Recent Posts'
        ELSE 'Other Posts'
    END AS PostClassification
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(string_to_array(rp.Tags, ','))
WHERE 
    rp.PostRank <= 100 
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.CommentCount, rp.PostRank
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
