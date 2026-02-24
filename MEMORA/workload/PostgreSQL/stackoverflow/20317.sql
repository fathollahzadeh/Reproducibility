
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE
        u.Reputation IS NOT NULL AND u.Reputation > 0
    GROUP BY
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(DISTINCT ph.UserId) AS EditorCount
    FROM
        PostHistory ph
        JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.PostId
),
FinalResults AS (
    SELECT
        ru.PostId,
        ru.Title,
        ru.CreationDate,
        ru.ViewCount,
        ru.Score,
        rh.HistoryTypes,
        rh.EditorCount,
        tu.TotalScore,
        tu.AvgReputation,
        tu.TotalPosts
    FROM
        RankedPosts ru
    LEFT JOIN PostHistoryDetails rh ON ru.PostId = rh.PostId
    LEFT JOIN TopUsers tu ON ru.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = tu.Id
    )
)

SELECT
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.Score,
    COALESCE(fr.HistoryTypes, 'No edits') AS HistoryTypes,
    COALESCE(fr.EditorCount, 0) AS EditorCount,
    CASE 
        WHEN fr.TotalScore IS NOT NULL AND fr.TotalPosts IS NOT NULL THEN fr.TotalScore / NULLIF(fr.TotalPosts, 0)
        ELSE 0 
    END AS AveragePostScore,
    CASE 
        WHEN fr.AvgReputation IS NOT NULL THEN CONCAT(CAST(fr.AvgReputation AS VARCHAR), ' (avg)')
        ELSE 'No reputation'
    END AS UserReputation
FROM
    FinalResults fr
WHERE
    fr.Score > COALESCE((SELECT AVG(Score) FROM Posts), 0)
ORDER BY
    fr.ViewCount DESC, 
    fr.CreationDate DESC
LIMIT 100;
