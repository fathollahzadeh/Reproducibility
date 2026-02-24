
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) >= 5 
)
SELECT 
    ru.DisplayName,
    ru.QuestionCount,
    ru.TotalScore,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    ph.Comment AS LastEditComment,
    ph.CreationDate AS LastEditDate
FROM 
    TopUsers ru
JOIN 
    RankedPosts rp ON ru.UserId = rp.PostId
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId 
    AND ph.PostHistoryTypeId = 4 
WHERE 
    rp.UserPostRank <= 3 
ORDER BY 
    ru.TotalScore DESC, 
    rp.Score DESC;
