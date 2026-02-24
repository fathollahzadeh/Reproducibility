WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPostsByTag AS (
    SELECT 
        PostId,
        Title,
        Tags,
        Owner,
        CreationDate,
        Score
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 
),
CommentsAggregate AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS CommentsText
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostSummary AS (
    SELECT 
        t.PostId,
        t.Title,
        t.Tags,
        t.Owner,
        t.CreationDate,
        t.Score,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(c.CommentsText, '') AS Comments,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = t.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = t.PostId AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        TopPostsByTag t
    LEFT JOIN 
        CommentsAggregate c ON t.PostId = c.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Tags,
    ps.Owner,
    ps.CreationDate,
    ps.Score,
    ps.TotalComments,
    ps.Comments,
    ps.UpVotes,
    ps.DownVotes,
    CASE 
        WHEN ps.Score > 100 THEN 'High Score'
        WHEN ps.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    PostSummary ps
ORDER BY 
    ps.CreationDate DESC, ps.Score DESC;