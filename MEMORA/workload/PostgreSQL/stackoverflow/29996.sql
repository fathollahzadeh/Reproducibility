
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        ProcessedTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10 
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.VoteTypeId IN (2, 3) 
    GROUP BY 
        v.UserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(uv.VoteCount, 0) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        UserVotes uv ON u.Id = uv.UserId
    WHERE 
        u.Reputation > 100 
),
RelevantPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.ViewCount
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CommentCount,
    au.DisplayName AS ActiveUser,
    au.VoteCount,
    pt.Tag,
    tc.TagCount
FROM 
    RelevantPosts rp
JOIN 
    ActiveUsers au ON au.Id IN (
        SELECT DISTINCT v.UserId 
        FROM Votes v WHERE v.PostId = rp.PostId
    )
JOIN 
    ProcessedTags pt ON pt.PostId = rp.PostId
JOIN 
    TagCounts tc ON pt.Tag = tc.Tag
JOIN 
    (SELECT 
         at.Tag,
         ARRAY_AGG(DISTINCT au.DisplayName) AS Users 
     FROM 
         ProcessedTags at
     JOIN 
         Votes v ON at.PostId = v.PostId AND v.VoteTypeId = 2 
     JOIN 
         ActiveUsers au ON v.UserId = au.Id
     GROUP BY 
         at.Tag) AS TagUsers ON TagUsers.Tag = pt.Tag
ORDER BY 
    rp.ViewCount DESC
LIMIT 10;
