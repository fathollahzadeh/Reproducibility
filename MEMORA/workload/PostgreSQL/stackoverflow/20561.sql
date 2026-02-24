WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        p.AnswerCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation < 1000 THEN 'Novice'
            WHEN u.Reputation BETWEEN 1000 AND 5000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM 
        Users u
),
RecentBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months')
    GROUP BY 
        b.UserId
),
PostComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id, 
        ph.PostId, 
        ph.CreationDate AS ClosedDate, 
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
)

SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.ViewCount, 
    rp.Score, 
    rp.AnswerCount, 
    rp.RankScore, 
    ur.ReputationLevel,
    rb.BadgeCount,
    pc.CommentCount,
    cp.ClosedDate, 
    cp.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON rp.PostId = ur.UserId
LEFT JOIN 
    RecentBadges rb ON ur.UserId = rb.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.RankScore <= 5
ORDER BY 
    rp.Score DESC, rp.AnswerCount DESC
LIMIT 50;