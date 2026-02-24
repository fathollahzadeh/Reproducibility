
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        ph.Level + 1 AS Level
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
TopTags AS (
    SELECT 
        LOWER(TRIM(t.TagName)) AS TagName,
        COUNT(DISTINCT p.Id) AS TagCount
    FROM Tags t
    INNER JOIN Posts p ON t.Id = p.Id
    GROUP BY LOWER(TRIM(t.TagName))
    HAVING COUNT(DISTINCT p.Id) > 5
),
AggregatedHistory AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.PostId) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes
    FROM PostHistory h
    JOIN PostHistoryTypes pht ON h.PostHistoryTypeId = pht.Id
    JOIN Posts p ON p.Id = h.PostId
    JOIN PostHierarchy ph ON ph.PostId = p.Id
    GROUP BY ph.PostId
),
CombinedData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ur.Reputation,
        ur.PostCount,
        ur.TotalBounty,
        oh.EditCount,
        oh.LastEditDate,
        oh.PostHistoryTypes,
        tt.TagCount
    FROM UserReputation ur
    JOIN Users u ON u.Id = ur.UserId
    LEFT JOIN AggregatedHistory oh ON ur.PostCount > 0
    LEFT JOIN TopTags tt ON tt.TagName IS NOT NULL
)
SELECT 
    c.UserId,
    c.DisplayName,
    c.Reputation,
    COALESCE(c.TotalBounty, 0) AS TotalBounty,
    COALESCE(c.EditCount, 0) AS EditCount,
    COALESCE(c.LastEditDate, '1970-01-01') AS LastEditDate,
    COALESCE(c.PostHistoryTypes, 'None') AS PostHistoryTypes,
    COALESCE(c.TagCount, 0) AS TagCount
FROM CombinedData c
WHERE c.Reputation > 100 AND COALESCE(c.EditCount, 0) >= 5
ORDER BY c.Reputation DESC, c.PostCount DESC
LIMIT 100;
