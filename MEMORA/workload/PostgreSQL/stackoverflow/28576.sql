WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(v.Id) DESC, COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName
),
FrequentTags AS (
    SELECT 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') 
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
),
PostAggregate AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        COALESCE(ft.TagCount, 0) AS FrequentTagCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        FrequentTags ft ON rp.Title ILIKE '%' || ft.TagName || '%'
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.OwnerDisplayName,
    pa.CommentCount,
    pa.VoteCount,
    pa.FrequentTagCount
FROM 
    PostAggregate pa
ORDER BY 
    pa.VoteCount DESC, pa.CommentCount DESC
LIMIT 20;