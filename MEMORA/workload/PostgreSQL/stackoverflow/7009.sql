WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
TopQuestions AS (
    SELECT *
    FROM RankedPosts
    WHERE RankByScore = 1
),
UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users U
    JOIN 
        Posts p ON U.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeTotal
    FROM 
        Badges B
    WHERE 
        B.Class = 1 
    GROUP BY 
        B.UserId
)
SELECT 
    U.DisplayName,
    US.TotalScore,
    US.QuestionCount,
    COALESCE(BC.BadgeTotal, 0) AS GoldBadges,
    COUNT(C.Id) AS CommentCount,
    SUM(P.Score) AS TotalPostScore
FROM 
    UserScores US
JOIN 
    Users U ON US.UserId = U.Id
LEFT JOIN 
    BadgeCounts BC ON U.Id = BC.UserId
LEFT JOIN 
    Comments C ON C.UserId = U.Id
LEFT JOIN 
    Posts P ON P.OwnerUserId = U.Id
WHERE 
    U.Reputation >= 1000 
GROUP BY 
    U.DisplayName, US.TotalScore, US.QuestionCount, BC.BadgeTotal
ORDER BY 
    TotalScore DESC, GoldBadges DESC, QuestionCount DESC
LIMIT 10;