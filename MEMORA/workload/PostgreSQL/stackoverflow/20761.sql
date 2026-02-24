
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN V.VoteTypeId = 1 THEN 1 END) AS AcceptedVotes,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.UserId AS EditorId,
        PH.CreationDate,
        PH.Comment,
        P.Title,
        P.AcceptedAnswerId
    FROM 
        PostHistory PH
    INNER JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (6, 10, 12) 
),
BadgeHistory AS (
    SELECT 
        U.Id AS UserId,
        STRING_AGG(B.Name, ', ') AS BadgesAwarded
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    UActivity.AcceptedVotes,
    UActivity.UpVotes,
    UActivity.DownVotes,
    US.AnswerCount, 
    US.QuestionCount,
    US.BadgeCount,
    US.UserRank,
    PH.Title AS LastEditedPostTitle,
    PH.Comment AS LastEditComment,
    PH.CreationDate AS LastEditDate,
    BA.BadgesAwarded
FROM 
    UserStats US
LEFT JOIN 
    UserActivity UActivity ON US.UserId = UActivity.UserId
LEFT JOIN 
    PostHistoryDetails PH ON US.UserId = PH.EditorId 
LEFT JOIN 
    BadgeHistory BA ON US.UserId = BA.UserId
WHERE 
    (US.UserRank <= 10 OR US.BadgeCount > 5) 
ORDER BY 
    US.UserRank, US.Reputation DESC;
