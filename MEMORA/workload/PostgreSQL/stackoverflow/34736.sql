
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
        AND p.PostTypeId = 1  
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '365 days' 
        AND p.PostTypeId = 1  
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 5
    ORDER BY 
        u.Reputation DESC, 
        QuestionCount DESC
    LIMIT 10
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        tu.DisplayName,
        tu.Reputation,
        tu.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY rp.CreationDate DESC) AS OverallRank
    FROM 
        RecentPosts rp
    JOIN 
        TopUsers tu ON rp.OwnerUserId = tu.UserId
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.Score,
    cd.ViewCount,
    cd.AnswerCount,
    cd.DisplayName,
    cd.Reputation,
    cd.TotalBounty,
    CASE 
        WHEN cd.Score > 10 THEN 'High Score'
        WHEN cd.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
        ELSE 'Low or No Score'
    END AS ScoreCategory,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Posts WHERE AcceptedAnswerId = cd.PostId
        ) THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus
FROM 
    CombinedData cd
WHERE 
    cd.OverallRank <= 50
ORDER BY 
    cd.CreationDate DESC
LIMIT 20;
