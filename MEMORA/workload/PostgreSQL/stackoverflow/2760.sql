
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.TotalScore,
    u.PostCount,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.Rank,
    COALESCE(cr.CloseReason, 'No Closure') AS ClosureDetails,
    CASE 
        WHEN rp.CommentCount = 0 THEN 'No Comments'
        ELSE CONCAT(rp.CommentCount, ' Comments')
    END AS CommentsStatus
FROM 
    TopUsers u
JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    u.TotalScore DESC, 
    rp.Score DESC;
