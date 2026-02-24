
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 6) 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.OwnerUserId
),
FilteredRankedPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Body,
        r.Tags,
        r.VoteCount,
        r.CommentCount
    FROM 
        RankedPosts r
    WHERE 
        r.UserRank <= 10 
),
TagStats AS (
    SELECT 
        TRIM(BOTH '<>' FROM Tag) AS TagName,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            UNNEST(string_to_array(Trim(both '<>' FROM Tags), '> <')) AS Tag
        FROM 
            FilteredRankedPosts
    ) AS TagArray
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        SUM(TagCount) AS TotalCount
    FROM 
        TagStats
    GROUP BY 
        TagName
    ORDER BY 
        TotalCount DESC
    LIMIT 5 
)

SELECT 
    fp.Title,
    fp.Body,
    fp.VoteCount,
    fp.CommentCount,
    tt.TagName,
    tt.TotalCount
FROM 
    FilteredRankedPosts fp
JOIN 
    TopTags tt ON fp.Tags LIKE CONCAT('%', tt.TagName, '%')
ORDER BY 
    fp.VoteCount DESC, 
    fp.CommentCount DESC;
