
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.UserDisplayName || ': ' || ph.Comment, ', ') AS EditComments,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    tu.DisplayName AS TopUser,
    ph.EditComments,
    ph.LastEditDate,
    CASE 
        WHEN rp.CommentCount > 10 THEN 'High Engagement'
        WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.UserRank = 1
LEFT JOIN 
    PostHistoryInfo ph ON rp.Id = ph.PostId
WHERE 
    rp.UserRank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
