
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(DISTINCT v.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.LastActivityDate, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Author,
        TotalComments,
        TotalVotes,
        CreationDate,
        LastActivityDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
TagsCount AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' ) OR p.Tags LIKE CONCAT('%<', t.TagName , ',%') OR p.Tags LIKE CONCAT('%,', t.TagName, '>') 
    GROUP BY 
        t.Id, t.TagName
),
FinalBenchmark AS (
    SELECT 
        fp.Title,
        fp.Author,
        fp.TotalComments,
        fp.TotalVotes,
        fp.CreationDate,
        fp.LastActivityDate,
        STRING_AGG(DISTINCT tc.TagName, ', ') AS RelatedTags
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Posts p ON fp.PostId = p.Id
    LEFT JOIN 
        TagsCount tc ON p.Tags LIKE CONCAT('%<', tc.TagName, '>%' ) OR p.Tags LIKE CONCAT('%<', tc.TagName , ',%') OR p.Tags LIKE CONCAT('%,', tc.TagName, '>') 
    GROUP BY 
        fp.PostId, fp.Title, fp.Author, fp.TotalComments, fp.TotalVotes, fp.CreationDate, fp.LastActivityDate
)

SELECT 
    *
FROM 
    FinalBenchmark
ORDER BY 
    TotalVotes DESC;
