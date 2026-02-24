
WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        B.Name AS BadgeName,
        B.Class,
        B.Date AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM Users U
    JOIN Badges B ON U.Id = B.UserId
),
FrequentTags AS (
    SELECT 
        P.OwnerUserId,
        STRING_AGG(T.TagName, ', ') AS Tags,
        COUNT(*) AS PostCount
    FROM Posts P
    JOIN UNNEST(STRING_TO_ARRAY(P.Tags, '>')) AS TagList ON TRUE
    JOIN Tags T ON T.TagName = TRIM(BOTH '<>' FROM TagList)
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName
),
CombinedData AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        UB.BadgeName,
        UB.Class,
        FT.Tags,
        UA.UpVotes,
        UA.DownVotes,
        UA.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY UB.BadgeDate DESC) AS UserRank
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN FrequentTags FT ON U.Id = FT.OwnerUserId
    LEFT JOIN UserActivity UA ON U.Id = UA.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeName,
    Class,
    Tags,
    UpVotes,
    DownVotes,
    CommentCount
FROM CombinedData
WHERE UserRank = 1 OR Tags IS NOT NULL
ORDER BY Reputation DESC, UpVotes DESC
LIMIT 50;
