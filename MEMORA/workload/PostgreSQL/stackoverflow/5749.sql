
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        upvotes.UpVoteCount,
        downvotes.DownVoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        p.ViewCount,
        r.Rank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS UpVoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) upvotes ON p.Id = upvotes.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS DownVoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 3 
        GROUP BY 
            PostId
    ) downvotes ON p.Id = downvotes.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    JOIN (
        SELECT 
            Id, 
            RANK() OVER (ORDER BY Score DESC, CreationDate ASC) AS Rank 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 1 
    ) r ON p.Id = r.Id
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    rp.UpVoteCount, 
    rp.DownVoteCount, 
    rp.CommentCount, 
    rp.ViewCount, 
    rp.Rank,
    u.DisplayName AS Owner,
    u.Reputation
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Rank;
