WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(COALESCE(v.VoteValue, 0)) AS TotalScore,
        MAX(u.Reputation) AS Reputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN (
        SELECT 
            v.PostId,
            SUM(CASE 
                WHEN v.VoteTypeId = 2 THEN 1 
                WHEN v.VoteTypeId = 3 THEN -1 
                ELSE 0 
            END) AS VoteValue
        FROM 
            Votes v
        GROUP BY 
            v.PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.QuestionsAsked,
        us.TotalScore,
        us.Reputation,
        ROW_NUMBER() OVER (ORDER BY us.TotalScore DESC, us.Reputation DESC) AS Rank
    FROM 
        UserStats us
    WHERE 
        us.Reputation > 1000  
)
SELECT 
    tu.DisplayName,
    tu.QuestionsAsked,
    tu.TotalScore,
    RP.PostId,
    RP.Title,
    RP.CreationDate
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts RP ON tu.UserId = RP.OwnerUserId AND RP.rn = 1  
WHERE 
    tu.Rank <= 10  
ORDER BY 
    tu.TotalScore DESC, 
    tu.Reputation DESC;