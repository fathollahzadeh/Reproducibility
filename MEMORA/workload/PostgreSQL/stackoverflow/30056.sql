WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    us.QuestionCount,
    us.TotalBounties,
    tp.PostId,
    tp.Title,
    tp.Score,
    tb.Badges,
    COALESCE(phs.CloseCount, 0) AS CloseCount,
    COALESCE(phs.DeleteCount, 0) AS DeleteCount,
    CASE 
        WHEN tp.LastActivityDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active'
    END AS UserActivityStatus
FROM 
    Users u
JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts tp ON u.Id = tp.OwnerUserId AND tp.PostRank <= 3
LEFT JOIN 
    TopBadges tb ON u.Id = tb.UserId
LEFT JOIN 
    PostHistorySummary phs ON tp.PostId = phs.PostId
WHERE 
    us.QuestionCount > 0
ORDER BY 
    us.QuestionCount DESC, 
    us.TotalBounties DESC;