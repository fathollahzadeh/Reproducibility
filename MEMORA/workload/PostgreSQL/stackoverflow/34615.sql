WITH RECURSIVE MostActiveUsers AS (
    SELECT
        U.Id,
        U.DisplayName,
        COUNT(P.Id) AS PostCount
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName
    HAVING
        COUNT(P.Id) > 0
    ORDER BY
        PostCount DESC
    LIMIT 5
),
UserBadges AS (
    SELECT
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id
),
PostUpdates AS (
    SELECT
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        PH.UserId AS EditorId,
        PH.UserDisplayName,
        P.Title,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM
        PostHistory PH
    JOIN
        Posts P ON PH.PostId = P.Id
    WHERE
        PH.PostHistoryTypeId IN (4, 5, 6) 
)
SELECT
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    COALESCE(UB.BadgeNames, 'None') AS BadgeNames,
    SUM(P.Score) AS TotalScore,
    SUM(P.ViewCount) AS TotalViews,
    ARRAY_AGG(DISTINCT P.Title) AS UserPosts,
    COUNT(DISTINCT C.Id) AS CommentCount,
    MAX(P.LastActivityDate) AS LastActiveDate
FROM
    Users U
LEFT JOIN
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN
    Comments C ON P.Id = C.PostId
LEFT JOIN
    PostUpdates PU ON P.Id = PU.PostId AND PU.rn = 1
WHERE
    U.Reputation > 1000
GROUP BY
    U.DisplayName, U.Reputation, UB.BadgeCount, UB.BadgeNames
HAVING
    COUNT(P.Id) > 3
ORDER BY
    TotalScore DESC;