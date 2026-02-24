WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostScore AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        COALESCE(
            (SELECT SUM(v.BountyAmount) 
             FROM Votes v 
             WHERE v.PostId = p.Id AND v.VoteTypeId = 8), 0) AS TotalBounty,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.Score IS NOT NULL
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Comments c
    GROUP BY c.PostId
),
CloseReason AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE 
            WHEN ph.Comment IS NULL THEN 'No reason given' 
            ELSE cr.Name 
        END, ', ') AS CloseReasons
    FROM PostHistory ph
    LEFT JOIN CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE ph.PostHistoryTypeId IN (10, 11)
    GROUP BY ph.PostId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Score,
        ur.Reputation AS OwnerReputation,
        pc.CommentCount,
        cr.CloseReasons
    FROM PostScore ps
    JOIN UserReputation ur ON ps.OwnerUserId = ur.UserId
    LEFT JOIN PostComments pc ON ps.PostId = pc.PostId
    LEFT JOIN CloseReason cr ON ps.PostId = cr.PostId
    WHERE ps.PostRank <= 5 
)
SELECT 
    tp.PostId,
    tp.Score,
    tp.OwnerReputation,
    tp.CommentCount,
    COALESCE(tp.CloseReasons, 'Open') AS CloseStatus,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)) AS BadgeCount
FROM TopPosts tp
ORDER BY tp.OwnerReputation DESC, tp.Score DESC;