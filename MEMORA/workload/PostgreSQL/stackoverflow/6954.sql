WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS QuestionCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        OwnerRank <= 5
    GROUP BY 
        OwnerDisplayName
),
UserBadges AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    tu.OwnerDisplayName,
    tu.QuestionCount,
    tu.TotalScore,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    TopUsers tu
JOIN 
    UserBadges ub ON tu.OwnerDisplayName = ub.DisplayName
ORDER BY 
    tu.QuestionCount DESC, tu.TotalScore DESC;