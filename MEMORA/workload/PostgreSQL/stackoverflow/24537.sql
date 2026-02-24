WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(ustr.PostCount, 0) AS UserPostCount,
    COALESCE(ustr.PopularPostCount, 0) AS UserPopularPostCount,
    pht.LastClosedDate,
    pht.LastReopenedDate,
    CASE
        WHEN rp.PostTypeId = 1 AND rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        WHEN rp.PostTypeId = 1 AND rp.AcceptedAnswerId IS NULL THEN 'Unaccepted'
        ELSE 'Not Applicable'
    END AS AcceptanceStatus,
    CASE 
        WHEN ustr.AverageReputation IS NULL THEN 'No Reputation Data'
        WHEN ustr.AverageReputation < 100 THEN 'Beginner'
        WHEN ustr.AverageReputation < 500 THEN 'Intermediate'
        ELSE 'Veteran'
    END AS UserExperienceLevel
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserStats ustr ON ustr.UserId = u.Id
LEFT JOIN 
    PostHistoryDetails pht ON pht.PostId = rp.PostId
WHERE 
    rp.Rank <= 3 
ORDER BY 
    rp.CreationDate DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;