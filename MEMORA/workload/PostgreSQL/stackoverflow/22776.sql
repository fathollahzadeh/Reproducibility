WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts pp WHERE pp.OwnerUserId = u.Id) AS TotalPosts,
        (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id AND v.VoteTypeId = 2) AS TotalUpVotes
    FROM 
        Users u
), 
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        COALESCE(ur.Reputation, 0) AS UserReputation,
        CASE 
            WHEN ur.TotalPosts IS NULL OR ur.TotalPosts = 0 THEN 'New User'
            ELSE 'Active User'
        END AS UserStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.PostRank <= 5
), 
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS TotalCloseReopenCount,
        COUNT(*) AS TotalEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CommentCount,
    fp.UserReputation,
    fp.UserStatus,
    ph.FirstEditDate,
    ph.LastEditDate,
    ph.TotalCloseReopenCount,
    ph.TotalEdits,
    CASE
        WHEN fp.CommentCount > 10 AND fp.UserStatus = 'Active User' THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryCTE ph ON fp.PostId = ph.PostId
WHERE 
    (fp.UserReputation > 1000 OR fp.CommentCount > 5)
    AND NOT EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.Id = fp.PostId AND p.ClosedDate IS NOT NULL
    )
ORDER BY 
    fp.UserReputation DESC, 
    fp.CommentCount DESC;