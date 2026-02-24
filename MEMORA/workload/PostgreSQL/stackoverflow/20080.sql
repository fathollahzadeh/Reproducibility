WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserVoteSummary AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.UserDisplayName, ', ') AS CommentingUsers
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    COALESCE(u.Reputation, 0) AS UserReputation,
    COALESCE(uts.Upvotes, 0) AS TotalUpvotes,
    COALESCE(uts.Downvotes, 0) AS TotalDownvotes,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pc.CommentingUsers, 'No comments') AS CommentingUsers
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    UserVoteSummary uts ON u.Id = uts.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.Rank <= 5
    AND rp.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC;