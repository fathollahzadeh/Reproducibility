WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.AnswerCount,
        p.ClosedDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(b.Reputation, 0), 1) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users b ON p.OwnerUserId = b.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5  
),
VotingHistory AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    rp.ViewCount,
    COALESCE(uh.PostsCreated, 0) AS UserPostsCreated,
    COALESCE(uh.CommentsMade, 0) AS UserCommentsMade,
    COALESCE(vh.UpVotes, 0) AS UpVotes,
    COALESCE(vh.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN rp.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS Status,
    CASE 
        WHEN rp.Rank = 1 THEN 'Most Recent'
        ELSE 'Earlier Post'
    END AS PostRank
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserActivity uh ON u.Id = uh.UserId
LEFT JOIN 
    VotingHistory vh ON rp.PostId = vh.PostId
WHERE 
    rp.Rank <= 3  
ORDER BY 
    rp.CreationDate DESC;