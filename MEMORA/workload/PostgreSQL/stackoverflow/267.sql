
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users)
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.CreationDate
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        tu.DisplayName AS TopUserName,
        CASE 
            WHEN cp.CloseCount IS NOT NULL THEN 'Closed' 
            ELSE 'Active' 
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopUsers tu ON rp.RankScore = 1
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)

SELECT 
    *
FROM 
    FinalResults
WHERE 
    (PostStatus = 'Active' AND Score > 10) OR 
    (PostStatus = 'Closed' AND CommentCount < 5)
ORDER BY 
    PostStatus DESC, CreationDate DESC
LIMIT 100;
