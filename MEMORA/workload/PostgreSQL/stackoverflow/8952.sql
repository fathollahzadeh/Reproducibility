WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AnswerCount,
        p.CommentCount,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.ParentId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
FilteredPosts AS (
    SELECT 
        rp.*,
        (SELECT AVG(Score) FROM Posts) AS AvgScore,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS TotalComments
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.CreationDate,
    fp.AnswerCount,
    fp.CommentCount,
    fp.LastActivityDate,
    fp.OwnerDisplayName,
    fp.Upvotes,
    fp.Downvotes,
    fp.AvgScore,
    fp.TotalComments
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC
LIMIT 50;
