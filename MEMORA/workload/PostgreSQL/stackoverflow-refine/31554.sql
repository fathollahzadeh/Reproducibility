WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        B.Name AS BadgeName, 
        B.Class, 
        B.Date,
        ROW_NUMBER() OVER(PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
),
PostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 6) THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN PH.Id IS NOT NULL THEN 1 END) AS HistoricalEdits
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        SUM(PA.UpVotes) AS TotalUpVotes,
        SUM(PA.DownVotes) AS TotalDownVotes,
        SUM(PA.CommentCount) AS TotalComment,
        SUM(PA.HistoricalEdits) AS TotalEdits
    FROM 
        Users U
    LEFT JOIN 
        PostActivity PA ON U.Id = PA.OwnerUserId
    GROUP BY 
        U.Id
),
FilteredUsers AS (
    SELECT 
        U.DisplayName, 
        UB.BadgeName,
        UPS.TotalUpVotes,
        UPS.TotalDownVotes,
        UPS.TotalComment,
        UPS.TotalEdits
    FROM 
        Users U
    JOIN 
        UserBadges UB ON U.Id = UB.UserId
    JOIN 
        UserPostStats UPS ON U.Id = UPS.UserId
    WHERE 
        UB.BadgeRank = 1 AND
        U.Reputation > 1000
)
SELECT 
    FU.DisplayName, 
    FU.BadgeName,
    COALESCE(FU.TotalUpVotes, 0) AS UpVotes,
    COALESCE(FU.TotalDownVotes, 0) AS DownVotes,
    COALESCE(FU.TotalComment, 0) AS CommentCount,
    COALESCE(FU.TotalEdits, 0) AS HistoricalEdits
FROM 
    FilteredUsers FU
ORDER BY 
    FU.TotalUpVotes DESC, 
    FU.TotalDownVotes ASC;