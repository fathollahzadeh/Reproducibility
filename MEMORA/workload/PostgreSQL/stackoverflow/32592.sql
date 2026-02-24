
WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
)
SELECT 
    ud.DisplayName,
    ud.Reputation,
    ud.TotalBadges,
    ud.TotalQuestions,
    ud.AverageScore,
    r.PostId,
    r.Title,
    r.ViewCount,
    r.Score,
    r.CreationDate,
    e.UserDisplayName AS LastEditor,
    e.CreationDate AS LastEditDate,
    CASE 
        WHEN e.EditRank IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus
FROM 
    UserDetails ud
INNER JOIN 
    RecursivePostCTE r ON ud.UserId = r.OwnerUserId
LEFT JOIN 
    RecentEdits e ON r.PostId = e.PostId AND e.EditRank = 1
WHERE 
    ud.Reputation > 1000
ORDER BY 
    ud.Reputation DESC, r.ViewCount DESC;
