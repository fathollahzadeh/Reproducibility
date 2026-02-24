WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.*,
        COALESCE(b.Name, 'No Badge') AS UserBadge,
        u.Reputation,
        CASE 
            WHEN COALESCE(vs.TotalDownvotes, 0) > 0 THEN 
                'Moderated'
            ELSE 
                'Regular'
        END AS PostType
    FROM RankedPosts rp
    LEFT JOIN Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId AND b.Class = 1 
    LEFT JOIN (
        SELECT 
            p.OwnerUserId,
            SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
        FROM Posts p
        JOIN Votes v ON p.Id = v.PostId
        GROUP BY p.OwnerUserId
    ) vs ON rp.OwnerUserId = vs.OwnerUserId
    WHERE rp.PostRank <= 5
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    tp.PostId,
    tp.Title AS PostTitle,
    tp.UserBadge,
    tp.Reputation AS UserReputation,
    tp.CommentCount,
    tp.TotalUpvotes,
    tp.TotalDownvotes,
    cp.ClosedPostId,
    cp.CloseReason
FROM TopPosts tp
LEFT JOIN ClosedPosts cp ON tp.PostId = cp.ClosedPostId
WHERE 
    tp.Reputation > 1000
    AND (tp.TotalUpvotes - tp.TotalDownvotes) > 10
ORDER BY 
    tp.TotalUpvotes DESC, tp.CommentCount DESC
LIMIT 50
OFFSET 0;