WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01' as date) - interval '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
MostActiveUsers AS (
    SELECT 
        us.UserId,
        SUM(us.QuestionCount - us.AcceptedAnswers) AS UnacceptedRatio
    FROM 
        UserStats us
    GROUP BY 
        us.UserId
    HAVING 
        SUM(us.QuestionCount - us.AcceptedAnswers) > 0
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    u.DisplayName AS OwnerDisplayName,
    CASE 
        WHEN ma.UnacceptedRatio IS NOT NULL THEN 'Check User' 
        ELSE 'All Good' 
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.Rank = 1 AND rp.PostId = (SELECT p2.Id FROM Posts p2 WHERE p2.OwnerUserId = u.Id AND p2.PostTypeId = 2 ORDER BY p2.CreationDate DESC LIMIT 1)
LEFT JOIN 
    MostActiveUsers ma ON u.Id = ma.UserId
WHERE 
    rp.ViewCount > 100
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC
LIMIT 100;