WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(b.Id) AS BadgeCount,
        RANK() OVER (ORDER BY SUM(p.ViewCount) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ru.DisplayName AS TopUser,
    ru.TotalViews,
    pu.Title AS TopPost,
    pu.ViewCount,
    pu.Score,
    COALESCE(ph.Comment, 'No close reason provided') AS CloseReason
FROM 
    TopUsers ru
JOIN 
    RankedPosts pu ON ru.UserId = pu.PostId
LEFT JOIN 
    PostHistory ph ON pu.PostId = ph.PostId 
        AND ph.PostHistoryTypeId IN (10, 11) 
        AND ph.CreationDate = (
            SELECT MAX(CreationDate)
            FROM PostHistory
            WHERE PostId = pu.PostId 
            AND PostHistoryTypeId IN (10, 11)
        )
WHERE 
    ru.UserRank <= 10
    AND pu.RankByScore = 1
ORDER BY 
    ru.TotalViews DESC;