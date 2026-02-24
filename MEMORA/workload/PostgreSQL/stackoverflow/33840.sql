
WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastEditDate,
        ph.UserDisplayName,
        ph.CreationDate AS HistoryCreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
        MAX(p.LastActivityDate) AS LastActiveDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CloseReopenCount,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        RecentActivity
    WHERE 
        PostCount > 0
)

SELECT 
    r.UserId, 
    r.DisplayName, 
    r.Reputation, 
    r.PostCount, 
    r.CloseReopenCount,
    p.Title,
    ph.Comment AS LatestHistoryComment,
    ph.HistoryCreationDate,
    NULLIF(p.ViewCount, 0) AS ViewCountAdjusted 
FROM 
    TopUsers r
LEFT JOIN 
    Posts p ON r.UserId = p.OwnerUserId AND p.LastEditDate IS NOT NULL
LEFT JOIN 
    RecursivePostHistory ph ON p.Id = ph.PostId AND ph.rn = 1
WHERE 
    r.UserRank <= 10
ORDER BY 
    r.Reputation DESC, r.PostCount DESC
LIMIT 10 OFFSET 0;
