
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS OwnerPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, p.OwnerUserId
),

UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostSummaries AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.CommentCount,
        rp.AnswerCount,
        um.DisplayName AS OwnerDisplayName,
        um.Reputation AS OwnerReputation
    FROM 
        RankedPosts rp
    JOIN 
        Users um ON rp.OwnerUserId = um.Id
    WHERE 
        rp.OwnerPostRank <= 3 
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.LastActivityDate,
    ps.CommentCount,
    ps.AnswerCount,
    ps.OwnerDisplayName,
    ps.OwnerReputation,
    COALESCE(pm.VoteCount, 0) AS VoteCount
FROM 
    PostSummaries ps
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
) pm ON ps.PostId = pm.PostId
ORDER BY 
    ps.OwnerReputation DESC, ps.CreationDate DESC
LIMIT 100;
