
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        QuestionCount DESC, TotalScore DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.QuestionCount,
    tu.TotalBadges,
    MAX(rp.ViewCount) AS MaxViewCount,
    MAX(rp.Score) AS MaxScore,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = tu.UserId AND PostTypeId = 2) AS AnswerCount
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
GROUP BY 
    tu.UserId, tu.DisplayName, tu.QuestionCount, tu.TotalBadges
HAVING 
    COUNT(DISTINCT rp.PostId) > 5
ORDER BY 
    tu.QuestionCount DESC, MaxScore DESC;
