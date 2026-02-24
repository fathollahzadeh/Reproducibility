
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionsAsked,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswersGiven,
        COALESCE(MAX(P.Score), 0) AS MaxPostScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPostHistory AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS Rn
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12, 13) 
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        P.Id
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.UpVotes,
    US.DownVotes,
    US.QuestionsAsked,
    US.AnswersGiven,
    US.MaxPostScore,
    COALESCE(RPH.CreationDate, NULL) AS LastActivityDate,
    PT.Tags,
    (SELECT COUNT(*) 
     FROM Comments C 
     WHERE C.UserId = US.UserId) AS TotalComments,
    (SELECT COUNT(*) 
     FROM PostHistory PH 
     WHERE PH.UserId = US.UserId AND PH.PostHistoryTypeId IN (22, 52, 53)) AS SpecialEvents
FROM 
    UserStats US
LEFT JOIN 
    RecentPostHistory RPH ON US.UserId = RPH.UserId AND RPH.Rn = 1
LEFT JOIN 
    PostTags PT ON PT.PostId = US.UserId
WHERE 
    US.UpVotes > US.DownVotes 
    AND (US.MaxPostScore > 10 OR US.QuestionsAsked > 0)
ORDER BY 
    US.Reputation DESC,
    US.DisplayName ASC
LIMIT 10;
