WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.AnswerCount, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High Reputation'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM 
        Users u
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.VoteCount,
    ur.DisplayName,
    ur.ReputationCategory,
    COALESCE(ur.Reputation, 0) AS UserReputation,
    COALESCE(ROUND(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - rp.CreationDate)) / 86400), 0) AS AgeInDays,
    CASE 
        WHEN rp.AnswerCount > 0 THEN 'Has Answers'
        ELSE 'No Answers'
    END AS AnswerStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.VoteCount DESC, rp.CreationDate DESC
LIMIT 100;