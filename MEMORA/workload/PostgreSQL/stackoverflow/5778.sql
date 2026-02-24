
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
ActiveUsers AS (
    SELECT 
        P.OwnerUserId AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.BadgeCount,
        A.PostCount,
        A.TotalScore,
        A.AvgViewCount,
        ROW_NUMBER() OVER (ORDER BY A.TotalScore DESC, A.PostCount DESC) AS Rank
    FROM 
        UserBadges U
    JOIN 
        ActiveUsers A ON U.UserId = A.UserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    PostCount,
    TotalScore,
    AvgViewCount,
    Rank
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
