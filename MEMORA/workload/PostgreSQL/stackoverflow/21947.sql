WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END), p.CreationDate) AS ClosedDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId AND b.Date <= p.CreationDate
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
RankedPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (PARTITION BY pd.OwnerUserId ORDER BY pd.Score DESC) AS OwnerPostRank
    FROM 
        PostDetails pd
)
SELECT 
    up.UserId,
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ClosedDate,
    rp.CommentCount,
    rp.BadgeCount,
    up.TotalVotes,
    up.Upvotes,
    up.Downvotes
FROM 
    UserVoteCounts up
JOIN 
    RankedPosts rp ON rp.OwnerUserId = up.UserId
JOIN 
    Users u ON up.UserId = u.Id
WHERE 
    ((rp.OwnerPostRank = 1 AND up.Upvotes > up.Downvotes) OR (rp.CommentCount > 10 AND rp.BadgeCount >= 1))
  AND 
    (rp.ClosedDate IS NULL OR rp.ClosedDate > rp.CreationDate)
ORDER BY 
    rp.Score DESC, 
    up.TotalVotes DESC
LIMIT 50;