
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT t.Tag) AS TagCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC, COUNT(v.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostTags t ON p.Id = t.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.VoteCount,
        rp.CommentCount,
        rp.TagCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 
)
SELECT 
    t.Tag,
    COUNT(*) AS NumberOfPosts,
    SUM(tr.ViewCount) AS TotalViewCount,
    SUM(tr.VoteCount) AS TotalVotes,
    SUM(tr.CommentCount) AS TotalComments
FROM 
    TopRankedPosts tr
JOIN 
    PostTags t ON tr.PostId = t.PostId
GROUP BY 
    t.Tag
ORDER BY 
    NumberOfPosts DESC, TotalViewCount DESC;
