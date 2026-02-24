
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, u.DisplayName, u.Reputation
),
PostTypeCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        PostTypeId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.Tags,
    ps.OwnerDisplayName,
    ps.OwnerReputation,
    pt.PostCount AS TotalPostsOfType
FROM 
    PostStats ps
JOIN 
    PostTypeCounts pt ON pt.PostTypeId = (SELECT PostTypeId FROM Posts WHERE Id = ps.PostId LIMIT 1)
ORDER BY 
    ps.CreationDate DESC;
