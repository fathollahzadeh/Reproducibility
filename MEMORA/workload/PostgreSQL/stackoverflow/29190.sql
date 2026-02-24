WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'  
    ORDER BY 
        p.CreationDate DESC
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS QuestionCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  
    GROUP BY 
        OwnerDisplayName
),
UserBadges AS (
    SELECT 
        u.DisplayName AS OwnerDisplayName,
        COUNT(b.Id) AS BadgeCount
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
    ub.BadgeCount
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.OwnerDisplayName = ub.OwnerDisplayName
ORDER BY 
    tu.TotalScore DESC,
    tu.QuestionCount DESC
LIMIT 10;