WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostWithVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Tags,
    ur.DisplayName AS Author,
    ur.Reputation AS AuthorReputation,
    pwc.UpvoteCount,
    pwc.DownvoteCount,
    CASE 
        WHEN rp.Score > 10 AND ur.Reputation >= 1000 THEN 'High Engagement'
        WHEN rp.Score <= 0 AND ur.Reputation < 100 THEN 'Low Engagement'
        ELSE 'Moderate Engagement'
    END AS EngagementLevel,
    CASE 
        WHEN rp.PostRank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
JOIN 
    Users ur ON rp.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE Id = rp.PostId) 
LEFT JOIN 
    PostWithVoteCounts pwc ON rp.PostId = pwc.PostId
WHERE 
    rp.PostRank <= 10
    AND ur.Reputation IS NOT NULL
ORDER BY 
    rp.Score DESC,
    ur.Reputation DESC;