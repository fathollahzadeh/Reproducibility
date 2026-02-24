WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year') AND 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(PostId) AS PostCount,
        SUM(AnswerCount) AS TotalAnswers
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
    GROUP BY 
        OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(tb.PostCount, 0) AS TotalQuestions,
    COALESCE(tb.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    TopUsers tb ON u.Id = tb.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC
LIMIT 10;