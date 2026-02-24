WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS VoterDisplayNames
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' )
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 2 
    LEFT JOIN 
        Users u ON u.Id = v.UserId
    GROUP BY 
        t.TagName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        t.TagName,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' )
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
),
Benchmark AS (
    SELECT 
        ts.TagName,
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.ViewCount,
        ps.Score,
        ps.CommentCount,
        ts.PostCount,
        ts.TotalCommentScore,
        ts.UniqueVoters,
        ts.VoterDisplayNames
    FROM 
        TagStats ts
    JOIN 
        PostSummary ps ON ts.TagName = ps.TagName
)
SELECT 
    b.TagName,
    b.PostId,
    b.Title,
    b.CreationDate,
    b.ViewCount,
    b.Score,
    b.CommentCount,
    b.PostCount,
    b.TotalCommentScore,
    b.UniqueVoters,
    b.VoterDisplayNames
FROM 
    Benchmark b
WHERE 
    b.PostCount > 0 
ORDER BY 
    b.PostCount DESC, 
    b.TotalCommentScore DESC, 
    b.UniqueVoters DESC;