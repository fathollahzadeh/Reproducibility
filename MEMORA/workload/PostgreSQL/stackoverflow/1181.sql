
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        SUM(Upvotes) AS TotalUpvotes,
        SUM(Downvotes) AS TotalDownvotes,
        COUNT(*) AS PostCount
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5
),
CloseReasonSummary AS (
    SELECT 
        postHistory.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory postHistory
    JOIN 
        CloseReasonTypes cr ON postHistory.Comment::INTEGER = cr.Id
    WHERE 
        postHistory.PostHistoryTypeId = 10
    GROUP BY 
        postHistory.PostId
)
SELECT 
    u.DisplayName,
    tp.TotalUpvotes,
    tp.TotalDownvotes,
    RANK() OVER (ORDER BY tp.TotalUpvotes DESC) AS UpvoteRank,
    tp.PostCount,
    cr.CloseReasons
FROM 
    TopUsers tp
JOIN 
    Users u ON u.Id = tp.OwnerUserId
LEFT JOIN 
    CloseReasonSummary cr ON cr.PostId IN (
        SELECT PostId FROM RankedPosts r WHERE r.OwnerUserId = u.Id
    )
WHERE 
    u.Reputation > 1000
    AND (tp.TotalDownvotes * 2) < tp.TotalUpvotes
ORDER BY 
    UpvoteRank, tp.PostCount DESC;
