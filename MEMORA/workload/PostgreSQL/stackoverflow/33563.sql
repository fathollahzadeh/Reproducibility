
WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
HighScoringPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.Score > 10
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(H.PostId) AS TotalEdits,
        COALESCE(SUM(CASE WHEN H.PostHistoryTypeId IN (2, 4) THEN 1 ELSE 0 END), 0) AS BodyEdits,
        COALESCE(SUM(CASE WHEN H.PostHistoryTypeId IN (1, 6) THEN 1 ELSE 0 END), 0) AS TitleEdits
    FROM 
        Users U
    LEFT JOIN 
        PostHistory H ON U.Id = H.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        UB.BadgeCount,
        UPS.TotalEdits,
        UPS.BodyEdits,
        UPS.TitleEdits
    FROM 
        Users U
    JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    JOIN 
        UserPostStats UPS ON U.Id = UPS.UserId
    WHERE 
        UB.BadgeCount > 5
)
SELECT 
    U.DisplayName,
    U.BadgeCount,
    U.TotalEdits,
    U.BodyEdits,
    U.TitleEdits,
    COUNT(DISTINCT P.PostId) AS HighScorePostsCount
FROM 
    TopUsers U
LEFT JOIN 
    HighScoringPosts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.DisplayName, U.BadgeCount, U.TotalEdits, U.BodyEdits, U.TitleEdits
ORDER BY 
    HighScorePostsCount DESC, U.BadgeCount DESC;
