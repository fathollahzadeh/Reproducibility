WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
BadgeStats AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(*) FILTER (WHERE B.Class = 1) AS GoldCount,
        COUNT(*) FILTER (WHERE B.Class = 2) AS SilverCount,
        COUNT(*) FILTER (WHERE B.Class = 3) AS BronzeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostHistorySummary AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS EditCount,
        STRING_AGG(DISTINCT PH.Comment, '; ') AS EditComments
    FROM 
        PostHistory PH
    WHERE
        PH.PostHistoryTypeId IN (4, 5, 6, 10, 11) 
    GROUP BY 
        PH.UserId, PH.PostId, PH.PostHistoryTypeId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.Questions,
    U.Answers,
    COALESCE(B.BadgeNames, 'No Badges') AS Badges,
    B.GoldCount,
    B.SilverCount,
    B.BronzeCount,
    COALESCE(PH.EditCount, 0) AS TotalEdits,
    COALESCE(PH.EditComments, 'No Edits') AS RecentEditComments
FROM 
    UserStats U
LEFT JOIN 
    BadgeStats B ON U.UserId = B.UserId
LEFT JOIN 
    PostHistorySummary PH ON U.UserId = PH.UserId
WHERE 
    U.Reputation > (
        SELECT AVG(Reputation) 
        FROM Users 
        WHERE Reputation IS NOT NULL
    )
ORDER BY 
    U.Reputation DESC
LIMIT 10;