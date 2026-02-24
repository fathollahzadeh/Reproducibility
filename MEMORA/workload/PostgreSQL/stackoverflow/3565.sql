WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldCount,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverCount,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostAggregate AS (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(B.GoldCount, 0) AS GoldCount,
        COALESCE(B.SilverCount, 0) AS SilverCount,
        COALESCE(B.BronzeCount, 0) AS BronzeCount,
        P.CommentCount,
        P.TotalScore,
        P.AvgViewCount,
        P.LastPostDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN UserBadgeCounts B ON U.Id = B.UserId
    LEFT JOIN PostAggregate P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 0
)
SELECT 
    A.DisplayName,
    A.Reputation,
    A.GoldCount,
    A.SilverCount,
    A.BronzeCount,
    A.CommentCount,
    A.TotalScore,
    A.AvgViewCount,
    A.LastPostDate
FROM ActiveUsers A
WHERE A.Rank <= 10
ORDER BY A.TotalScore DESC, A.LastPostDate DESC;
