WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        u.Reputation AS OwnerReputation,
        bt.Name AS BadgeType
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostHistoryTypes bt ON ph.PostHistoryTypeId = bt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '365 days'
        AND p.PostTypeId IN (1, 2)  
),
AggregateData AS (
    SELECT 
        rp.PostId,
        COUNT(rp.BadgeType) AS BadgeCount,
        AVG(rp.OwnerReputation) AS AverageReputation,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.Score) AS TotalScore
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.PostId
)
SELECT 
    ad.PostId,
    p.Title,
    ad.BadgeCount,
    ad.AverageReputation,
    ad.TotalViews,
    ad.TotalScore,
    CASE 
        WHEN ad.TotalScore > 100 THEN 'High Engagement'
        WHEN ad.TotalScore BETWEEN 50 AND 100 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    AggregateData ad
JOIN 
    Posts p ON ad.PostId = p.Id
ORDER BY 
    ad.TotalScore DESC
LIMIT 50;