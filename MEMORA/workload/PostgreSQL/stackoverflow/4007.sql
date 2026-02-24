
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(vs.Score, 0)) AS TotalScore,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT 
            PostId, SUM(Score) AS Score 
         FROM 
            Comments 
         GROUP BY 
            PostId
        ) AS vs ON p.Id = vs.PostId
    WHERE 
        u.Reputation > 500
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalScore, 
        BadgeCount,
        LastPostDate,
        RANK() OVER (ORDER BY TotalScore DESC, PostCount DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.BadgeCount,
    tu.LastPostDate,
    ph.Comment AS LastEditComment,
    COALESCE(NULLIF(p.AcceptedAnswerId, -1), p.ParentId) AS FinalPostLink
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    tu.Rank <= 10 
    AND ph.CreationDate = (SELECT MAX(ph2.CreationDate) FROM PostHistory ph2 WHERE ph2.PostId = p.Id)
ORDER BY 
    tu.TotalScore DESC;
