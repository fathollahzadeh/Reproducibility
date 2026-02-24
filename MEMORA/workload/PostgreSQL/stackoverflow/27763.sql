WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '90 days'  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
    WHERE 
        PostCount > 5 
),
RankedComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.OwnerDisplayName,
    r.CommentCount,
    r.VoteCount,
    tt.TagName,
    r.Rank,
    rc.TotalComments
FROM 
    RankedPosts r
JOIN 
    TopTags tt ON r.Tags LIKE '%' || tt.TagName || '%'
JOIN 
    RankedComments rc ON r.PostId = rc.PostId
WHERE 
    r.Rank <= 3 
ORDER BY 
    tt.TagName, r.VoteCount DESC, r.CommentCount DESC;