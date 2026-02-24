WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.PostTypeId, p.ViewCount
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS BadgePoints,
        COALESCE(SUM(v.BountyAmount), 0) AS BountyPoints
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserDisplayName AS ClosedBy,
        ph.CreationDate AS ClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
),
PostAnalysis AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Rank,
        COALESCE(u.DisplayName, 'Unknown') AS LastEditorDisplayName,
        cp.ClosedDate,
        cp.ClosedBy,
        rp.CommentCount,
        COALESCE(ur.BadgePoints + ur.BountyPoints, 0) AS UserScore,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top Performing'
            WHEN rp.Rank BETWEEN 6 AND 15 THEN 'Moderate Performing'
            ELSE 'Low Performing'
        END AS PerformanceCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        Users u ON p.LastEditorUserId = u.Id
    LEFT JOIN 
        ClosedPosts cp ON p.Id = cp.PostId
    LEFT JOIN 
        UserReputation ur ON p.OwnerUserId = ur.UserId
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Rank,
    pa.LastEditorDisplayName,
    pa.ClosedDate,
    pa.ClosedBy,
    pa.CommentCount,
    pa.UserScore,
    pa.PerformanceCategory
FROM 
    PostAnalysis pa
WHERE 
    pa.UserScore > 2 
ORDER BY 
    pa.UserScore DESC, 
    pa.Rank
LIMIT 100;