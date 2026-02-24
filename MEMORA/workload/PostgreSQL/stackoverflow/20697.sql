WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation, 
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        (SELECT UserId, MAX(Class) AS Class FROM Badges GROUP BY UserId) b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
),

UserPostStats AS (
    SELECT 
        ur.UserId,
        COUNT(DISTINCT rp.PostId) AS TotalQuestions,
        SUM(rp.Score) AS TotalScore,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    GROUP BY 
        ur.UserId
),

FinalStats AS (
    SELECT 
        ups.UserId,
        ups.TotalQuestions,
        ups.TotalScore,
        ups.TotalComments,
        ur.Reputation,
        ur.BadgeClass
    FROM 
        UserPostStats ups
    JOIN 
        UserReputation ur ON ups.UserId = ur.UserId
)

SELECT 
    fs.UserId,
    fs.TotalQuestions,
    fs.TotalScore,
    fs.TotalComments,
    fs.Reputation,
    CASE 
        WHEN fs.BadgeClass = 1 THEN 'Gold' 
        WHEN fs.BadgeClass = 2 THEN 'Silver' 
        WHEN fs.BadgeClass = 3 THEN 'Bronze' 
        ELSE 'No Badge' 
    END AS UserBadgeStatus,
    (SELECT COUNT(*) FROM Comments WHERE UserId = fs.UserId AND CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '7 days') AS RecentCommentsCount,
    (SELECT STRING_AGG(DISTINCT p.Tags, ', ') 
     FROM Posts p 
     WHERE p.OwnerUserId = fs.UserId 
       AND p.PostTypeId = 1 
       AND p.Tags IS NOT NULL) AS UserTags
FROM 
    FinalStats fs
WHERE 
    fs.TotalQuestions > 5
ORDER BY 
    fs.TotalScore DESC, fs.TotalQuestions DESC
LIMIT 10;