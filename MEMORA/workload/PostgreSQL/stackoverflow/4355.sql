WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM
        Users u
        JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE
        u.Reputation >= 1000
    GROUP BY
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM
        PostHistory ph
        JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.PostId
)
SELECT
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    tu.DisplayName AS TopUser,
    tu.TotalScore,
    phs.EditCount,
    phs.EditTypes
FROM
    RankedPosts rp
    LEFT JOIN TopUsers tu ON rp.Rank = 1 AND tu.PostCount > 5
    LEFT JOIN PostHistorySummary phs ON rp.Id = phs.PostId
WHERE
    (rp.ViewCount > 100 OR rp.CommentCount > 10)
    AND (phs.EditCount IS NULL OR phs.EditCount < 5)
ORDER BY
    rp.Score DESC,
    rp.ViewCount DESC;