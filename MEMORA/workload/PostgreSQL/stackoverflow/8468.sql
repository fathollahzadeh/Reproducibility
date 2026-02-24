WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalBadges DESC 
    LIMIT 10
)
SELECT 
    ru.DisplayName,
    COUNT(DISTINCT rp.PostId) AS RecentPostsCount,
    SUM(rp.ViewCount) AS TotalPostViews,
    SUM(rp.Score) AS TotalScore,
    SUM(tp.QuestionCount) AS TotalQuestions,
    SUM(tp.AnswerCount) AS TotalAnswers,
    AVG(tp.TotalBadges) AS AverageBadges
FROM 
    RankedPosts rp
JOIN 
    TopUsers tp ON rp.PostId = ANY (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = tp.UserId
    )
JOIN 
    Users ru ON tp.UserId = ru.Id
GROUP BY 
    ru.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 5
ORDER BY 
    TotalPostViews DESC;