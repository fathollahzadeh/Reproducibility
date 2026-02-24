
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN,
        COALESCE(NULLIF(u.Reputation, 0), 1) AS SafeReputation,
        CASE 
            WHEN p.Score > 10 THEN 'High'
            WHEN p.Score BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2 years' AND TIMESTAMP '2024-10-01 12:34:56'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    tu.DisplayName,
    tu.PositivePostCount,
    tu.NegativePostCount,
    CASE 
        WHEN tu.PositivePostCount > 10 AND tu.NegativePostCount = 0 THEN 'Sought After'
        WHEN tu.NegativePostCount > 0 THEN 'Controversial'
        ELSE 'Neutral'
    END AS UserReputationStatus,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount,
    STRING_AGG(DISTINCT CONCAT(pt.Name, ': ', pt.Id), ', ') AS PostHistoryTypes
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
WHERE 
    rp.RN = 1
GROUP BY 
    rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount, tu.DisplayName, tu.PositivePostCount, tu.NegativePostCount
ORDER BY 
    rp.Score DESC, tu.PositivePostCount DESC
LIMIT 50 OFFSET 0;
