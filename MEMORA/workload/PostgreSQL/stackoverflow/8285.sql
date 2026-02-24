WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        RANK() OVER (ORDER BY SUM(p.Score) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ru.DisplayName,
    ru.TotalScore,
    ru.TotalBadges,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.CommentCount) AS TotalComments,
    SUM(rp.AnswerCount) AS TotalAnswers
FROM 
    TopUsers ru
JOIN 
    RankedPosts rp ON ru.UserId = rp.OwnerUserId
WHERE 
    ru.UserRank <= 10
GROUP BY 
    ru.DisplayName, ru.TotalScore, ru.TotalBadges
ORDER BY 
    ru.TotalScore DESC, ru.DisplayName;
