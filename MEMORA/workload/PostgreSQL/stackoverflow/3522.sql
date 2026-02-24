
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),
RankedUsers AS (
    SELECT 
        ue.*,
        ROW_NUMBER() OVER (ORDER BY ue.PostCount DESC) AS Rank
    FROM UserEngagement ue
)

SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.PostCount,
    ru.TotalCommentScore,
    ru.TotalBounty,
    ru.LastPostDate,
    COALESCE(ph.CloseReopenCount, 0) AS CloseReopenCount,
    ph.LastHistoryDate,
    CASE 
        WHEN ru.PostCount > 100 THEN 'Experienced'
        WHEN ru.PostCount BETWEEN 50 AND 100 THEN 'Moderate'
        ELSE 'Novice'
    END AS ExperienceLevel
FROM RankedUsers ru
LEFT JOIN PostHistoryDetails ph ON ru.UserId = ph.PostId
WHERE ru.Rank <= 10
ORDER BY ru.TotalBounty DESC, ru.TotalCommentScore DESC
LIMIT 10 OFFSET 0;
