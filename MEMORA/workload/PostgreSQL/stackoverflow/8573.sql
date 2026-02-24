WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS AnsweredQuestions,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalQuestions,
        us.AnsweredQuestions,
        us.BadgeCount,
        (SELECT COUNT(*) FROM RankedPosts rp WHERE rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)) AS TopAnsweredQuestions
    FROM 
        UserStatistics us
    WHERE 
        us.TotalQuestions > 0
    ORDER BY 
        us.BadgeCount DESC, us.AnsweredQuestions DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.TotalQuestions,
    tu.AnsweredQuestions,
    tu.BadgeCount,
    COALESCE(ARRAY_AGG(rp.Title ORDER BY rp.ViewCount DESC), ARRAY[]::varchar[]) AS TopQuestions
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.PostId
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalQuestions, tu.AnsweredQuestions, tu.BadgeCount
ORDER BY 
    tu.BadgeCount DESC, tu.AnsweredQuestions DESC;
